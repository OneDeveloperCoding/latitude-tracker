#!/usr/bin/env python3
"""Second pass for generate_cp4_table.py: re-resolves CP4 entries that the
first pass missed because the CTT locality name doesn't match OSM verbatim —
CTT drops prepositions ("Sao Mamede Coronado" vs OSM's "São Mamede de
Coronado"), appends a 3-4 letter concelho code ("Arcozelo VNG"), or a
parenthetical disambiguator ("Calheta (Madeira)").

Builds a wildcard regex from the significant words of each miss (joining them
with ".*" so missing prepositions don't break the match), and when several
OSM candidates match, disambiguates using the CP4's region (mainland /
Madeira / Açores, inferred from the CP4 numeric range) via a rough
lat/lon bounding box.

Reads and rewrites assets/data/cp4_coordinates.json in place. Run after
generate_cp4_table.py.
"""

from __future__ import annotations

import csv
import io
import json
import re
import sys
import time
import unicodedata
import urllib.parse
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path

CTT_CSV_URL = (
    "https://raw.githubusercontent.com/centraldedados/codigos_postais/"
    "master/data/codigos_postais.csv"
)
OVERPASS_URL = "https://overpass-api.de/api/interpreter"
USER_AGENT = "LatitudeTracker-CP4TableGenerator/1.0 (one-time offline tool)"
OUTPUT_PATH = Path(__file__).resolve().parent.parent / "assets" / "data" / "cp4_coordinates.json"

STOPWORDS = {"de", "da", "do", "dos", "das", "e"}
PLACE_TYPE_RANK = ["city", "town", "village", "hamlet"]

# Rough bounding boxes (lat_min, lat_max, lon_min, lon_max) used only to pick
# between multiple same-named OSM candidates by region.
REGION_BBOX = {
    "madeira": (32.5, 33.2, -17.3, -16.2),
    "azores": (36.8, 39.8, -31.5, -24.5),
    "mainland": (36.8, 42.3, -9.6, -6.0),
}


def region_hint(cp4: str) -> str | None:
    prefix = int(cp4[:2])
    if 90 <= prefix <= 92:
        return "madeira"
    if 95 <= prefix <= 99:
        return "azores"
    return "mainland"


def normalize(name: str) -> str:
    decomposed = unicodedata.normalize("NFKD", name)
    stripped = "".join(c for c in decomposed if not unicodedata.combining(c))
    return stripped.lower()


def significant_words(name: str) -> list[str]:
    words = re.findall(r"[A-Za-zÀ-ÿ]+", name)
    return [w for w in words if normalize(w) not in STOPWORDS]


def fetch(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read()


def load_cp4_localities() -> dict[str, str]:
    raw = fetch(CTT_CSV_URL).decode("utf-8")
    reader = csv.DictReader(io.StringIO(raw))
    counts: dict[str, Counter[str]] = defaultdict(Counter)
    for row in reader:
        cp4 = row["num_cod_postal"].strip()
        locality = row["desig_postal"].strip()
        if cp4 and locality:
            counts[cp4][locality] += 1
    return {cp4: counter.most_common(1)[0][0] for cp4, counter in counts.items()}


_ACCENT_CLASSES = {
    "a": "[aàáâã]", "e": "[eèéê]", "i": "[iìíî]", "o": "[oòóôõ]", "u": "[uùúû]",
    "c": "[cç]",
}


def _accent_flexible(word: str) -> str:
    out = []
    for ch in word:
        base = unicodedata.normalize("NFKD", ch.lower())[0]
        out.append(_ACCENT_CLASSES.get(base, re.escape(ch)))
    return "".join(out)


def wildcard_pattern(name: str) -> str | None:
    words = significant_words(name)
    if not words:
        return None
    return ".*".join(_accent_flexible(w) for w in words)


def overpass_query(patterns: list[str]) -> list[dict]:
    alternation = "|".join(f"({p})" for p in patterns)
    query = (
        "[out:json][timeout:90];"
        'area["ISO3166-1"="PT"]->.pt;'
        f'node["place"]["name"~"^({alternation})$",i](area.pt);'
        "out center;"
    )
    body = urllib.parse.urlencode({"data": query}).encode("utf-8")
    req = urllib.request.Request(OVERPASS_URL, data=body, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.loads(resp.read())["elements"]


def in_bbox(lat: float, lon: float, region: str) -> bool:
    lat_min, lat_max, lon_min, lon_max = REGION_BBOX[region]
    return lat_min <= lat <= lat_max and lon_min <= lon <= lon_max


def pick_candidate(elements: list[dict], pattern: str, region: str | None) -> dict | None:
    rx = re.compile(f"^({pattern})$", re.IGNORECASE)
    candidates = [e for e in elements if rx.match(e.get("tags", {}).get("name", ""))]
    if not candidates:
        return None
    if region:
        in_region = [c for c in candidates if in_bbox(c["lat"], c["lon"], region)]
        if in_region:
            candidates = in_region
    if len(candidates) == 1:
        return candidates[0]

    def rank(e: dict) -> int:
        place = e.get("tags", {}).get("place", "")
        return PLACE_TYPE_RANK.index(place) if place in PLACE_TYPE_RANK else len(PLACE_TYPE_RANK)

    candidates.sort(key=rank)
    return candidates[0]


def main() -> None:
    table: dict[str, dict] = json.loads(OUTPUT_PATH.read_text(encoding="utf-8"))
    cp4_to_locality = load_cp4_localities()

    missing = {cp4: locality for cp4, locality in cp4_to_locality.items() if cp4 not in table}
    print(f"{len(missing)} CP4 entries still missing, attempting fuzzy resolution...", file=sys.stderr)

    pattern_by_cp4: dict[str, str] = {}
    for cp4, locality in missing.items():
        pattern = wildcard_pattern(locality)
        if pattern:
            pattern_by_cp4[cp4] = pattern

    cp4_list = list(pattern_by_cp4.items())
    batch_size = 5
    resolved = 0
    still_missing: list[str] = []

    for i in range(0, len(cp4_list), batch_size):
        batch = cp4_list[i : i + batch_size]
        patterns = [p for _, p in batch]
        print(f"Fuzzy batch {i // batch_size + 1} ({len(batch)} entries)...", file=sys.stderr)

        elements = None
        for attempt in range(1, 4):
            try:
                elements = overpass_query(patterns)
                break
            except Exception as exc:  # noqa: BLE001 - one-time script
                wait = 4.0 * attempt
                print(f"  attempt {attempt} failed ({exc}), retrying in {wait}s...", file=sys.stderr)
                time.sleep(wait)
        if elements is None:
            still_missing.extend(cp4 for cp4, _ in batch)
            continue

        for cp4, pattern in batch:
            match = pick_candidate(elements, pattern, region_hint(cp4))
            if match is None:
                still_missing.append(cp4)
            else:
                table[cp4] = {
                    "lat": match["lat"],
                    "lng": match["lon"],
                    "locality": match.get("tags", {}).get("name", cp4_to_locality[cp4]),
                }
                resolved += 1
        time.sleep(3.0)

    OUTPUT_PATH.write_text(json.dumps(table, ensure_ascii=False, indent=2, sort_keys=True), encoding="utf-8")

    print(f"\nResolved {resolved} more entries. Total now: {len(table)}/{len(cp4_to_locality)}.", file=sys.stderr)
    if still_missing:
        print(f"{len(still_missing)} CP4 prefixes remain unmatched (will be excluded from the heat map):", file=sys.stderr)
        for cp4 in sorted(still_missing):
            print(f"  - {cp4}: {cp4_to_locality[cp4]}", file=sys.stderr)


if __name__ == "__main__":
    main()
