#!/usr/bin/env python3
"""Third pass for generate_cp4_table.py: resolves the remaining CP4 entries
whose CTT locality name carries a disambiguation marker that isn't part of
the actual place name — a trailing 2-4 letter concelho code ("Arcozelo VNG")
or a parenthetical qualifier ("Calheta (Madeira)").

For the trailing-code case, OSM tags each concelho's administrative boundary
relation with the same official code CTT uses, as `nat_ref` (verified: the
Vila Nova de Gaia relation has nat_ref=VNG). So instead of guessing, we look
up the concelho boundary by nat_ref and scope the place-name search to
inside it — this also resolves same-name collisions for free.

For the parenthetical case (an island name — Madeira/São Miguel/São Jorge),
there's no nat_ref to key off; the CP4-derived region bounding box already
used in resolve_cp4_misses.py disambiguates instead.

Reads and rewrites assets/data/cp4_coordinates.json in place. Run after
resolve_cp4_misses.py.
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

REGION_BBOX = {
    "madeira": (32.5, 33.2, -17.3, -16.2),
    "azores": (36.8, 39.8, -31.5, -24.5),
    "mainland": (36.8, 42.3, -9.6, -6.0),
}
ISLAND_HINTS = {
    "madeira": "madeira",
    "sao miguel": "azores",
    "sao jorge": "azores",
    "acores": "azores",
}

SUFFIX_CODE_RE = re.compile(r"^(?P<base>.+?)\s+(?P<code>[A-Z]{2,4})$")
PARENTHETICAL_RE = re.compile(r"^(?P<base>.+?)\s*\((?P<qualifier>[^)]+)\)$")


def region_hint(cp4: str) -> str | None:
    prefix = int(cp4[:2])
    if 90 <= prefix <= 92:
        return "madeira"
    if 95 <= prefix <= 99:
        return "azores"
    return "mainland"


def normalize(name: str) -> str:
    decomposed = unicodedata.normalize("NFKD", name)
    return "".join(c for c in decomposed if not unicodedata.combining(c)).lower()


def fetch(url: str, data: bytes | None = None) -> bytes:
    req = urllib.request.Request(url, data=data, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=90) as resp:
        return resp.read()


def overpass(query: str) -> list[dict]:
    body = urllib.parse.urlencode({"data": query}).encode("utf-8")
    return json.loads(fetch(OVERPASS_URL, body))["elements"]


def overpass_retrying(query: str, attempts: int = 4) -> list[dict] | None:
    for attempt in range(1, attempts + 1):
        try:
            return overpass(query)
        except Exception as exc:  # noqa: BLE001 - one-time script
            wait = 4.0 * attempt
            print(f"    attempt {attempt} failed ({exc}), retrying in {wait}s...", file=sys.stderr)
            time.sleep(wait)
    return None


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


def name_pattern(base: str) -> str:
    words = re.findall(r"[A-Za-zÀ-ÿ]+", base)
    words = [w for w in words if normalize(w) not in {"de", "da", "do", "dos", "das", "e"}]
    accent_classes = {
        "a": "[aàáâã]", "e": "[eèéê]", "i": "[iìíî]", "o": "[oòóôõ]", "u": "[uùúû]", "c": "[cç]",
    }

    def flex(word: str) -> str:
        return "".join(
            accent_classes.get(unicodedata.normalize("NFKD", ch.lower())[0], re.escape(ch))
            for ch in word
        )

    return ".*".join(flex(w) for w in words)


def resolve_by_concelho_code(base: str, code: str) -> dict | None:
    query = (
        "[out:json][timeout:60];"
        f'relation["boundary"="administrative"]["nat_ref"="{code}"]->.c;'
        ".c map_to_area -> .a;"
        f'node["place"]["name"~"^({name_pattern(base)})$",i](area.a);'
        "out center;"
    )
    elements = overpass_retrying(query)
    if not elements:
        return None
    return elements[0]


def resolve_by_region(base: str, qualifier: str, cp4: str) -> dict | None:
    query = (
        "[out:json][timeout:60];"
        'area["ISO3166-1"="PT"]->.pt;'
        f'node["place"]["name"~"^({name_pattern(base)})$",i](area.pt);'
        "out center;"
    )
    elements = overpass_retrying(query)
    if not elements:
        return None

    region = ISLAND_HINTS.get(normalize(qualifier), region_hint(cp4))
    lat_min, lat_max, lon_min, lon_max = REGION_BBOX[region]
    in_region = [e for e in elements if lat_min <= e["lat"] <= lat_max and lon_min <= e["lon"] <= lon_max]
    return (in_region or elements)[0]


def main() -> None:
    table: dict[str, dict] = json.loads(OUTPUT_PATH.read_text(encoding="utf-8"))
    cp4_to_locality = load_cp4_localities()
    missing = {cp4: loc for cp4, loc in cp4_to_locality.items() if cp4 not in table}
    print(f"{len(missing)} CP4 entries remaining.", file=sys.stderr)

    resolved = 0
    still_missing = []

    for cp4, locality in sorted(missing.items()):
        paren = PARENTHETICAL_RE.match(locality)
        suffix = SUFFIX_CODE_RE.match(locality)

        match = None
        if paren:
            print(f"{cp4} ({locality}): resolving by region qualifier '{paren['qualifier']}'...", file=sys.stderr)
            match = resolve_by_region(paren["base"], paren["qualifier"], cp4)
        elif suffix:
            print(f"{cp4} ({locality}): resolving by concelho code '{suffix['code']}'...", file=sys.stderr)
            match = resolve_by_concelho_code(suffix["base"], suffix["code"])
        else:
            print(f"{cp4} ({locality}): no suffix pattern, retrying plain fuzzy match...", file=sys.stderr)
            query = (
                "[out:json][timeout:60];"
                'area["ISO3166-1"="PT"]->.pt;'
                f'node["place"]["name"~"^({name_pattern(locality)})$",i](area.pt);'
                "out center;"
            )
            elements = overpass_retrying(query)
            match = elements[0] if elements else None

        if match is None:
            print("  -> no match", file=sys.stderr)
            still_missing.append(cp4)
        else:
            table[cp4] = {
                "lat": match["lat"],
                "lng": match["lon"],
                "locality": match.get("tags", {}).get("name", locality),
            }
            print(f"  -> matched '{table[cp4]['locality']}' at ({match['lat']}, {match['lon']})", file=sys.stderr)
            resolved += 1

        time.sleep(3.5)

    OUTPUT_PATH.write_text(json.dumps(table, ensure_ascii=False, indent=2, sort_keys=True), encoding="utf-8")
    print(f"\nResolved {resolved} more entries. Total now: {len(table)}/{len(cp4_to_locality)}.", file=sys.stderr)
    if still_missing:
        print(f"{len(still_missing)} CP4 prefixes remain unmatched:", file=sys.stderr)
        for cp4 in still_missing:
            print(f"  - {cp4}: {cp4_to_locality[cp4]}", file=sys.stderr)


if __name__ == "__main__":
    main()
