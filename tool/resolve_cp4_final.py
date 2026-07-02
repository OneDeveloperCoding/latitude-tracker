#!/usr/bin/env python3
"""Fourth and final pass for generate_cp4_table.py: resolves the last CP4
entries where the OSM place name is a superset of the CTT name (e.g. CTT's
"CAPARICA" is OSM's "Costa da Caparica") or uses a CTT abbreviation
("STA" for "Santa"). Unlike the earlier passes, this one is NOT anchored —
it just requires all significant words to appear, in order, as a substring
of the OSM name, and picks the highest-ranked place type among matches.

Reads and rewrites assets/data/cp4_coordinates.json in place. Run after
resolve_cp4_suffix_codes.py.
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

PLACE_TYPE_RANK = ["city", "town", "village", "hamlet", "suburb", "neighbourhood"]
STOPWORDS = {"de", "da", "do", "dos", "das", "e"}
ABBREVIATIONS = {"sta": "santa", "sto": "santo", "s": "sao"}


def normalize(name: str) -> str:
    decomposed = unicodedata.normalize("NFKD", name)
    return "".join(c for c in decomposed if not unicodedata.combining(c)).lower()


def fetch(url: str, data: bytes | None = None) -> bytes:
    req = urllib.request.Request(url, data=data, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=90) as resp:
        return resp.read()


def overpass_retrying(query: str, attempts: int = 4) -> list[dict] | None:
    body = urllib.parse.urlencode({"data": query}).encode("utf-8")
    for attempt in range(1, attempts + 1):
        try:
            return json.loads(fetch(OVERPASS_URL, body))["elements"]
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


_ACCENT_CLASSES = {
    "a": "[aàáâã]", "e": "[eèéê]", "i": "[iìíî]", "o": "[oòóôõ]", "u": "[uùúû]",
    "c": "[cç]",
}


def accent_flexible(word: str) -> str:
    return "".join(
        _ACCENT_CLASSES.get(unicodedata.normalize("NFKD", ch.lower())[0], re.escape(ch))
        for ch in word
    )


def significant_words(name: str) -> list[str]:
    words = re.findall(r"[A-Za-zÀ-ÿ]+", name)
    out = []
    for w in words:
        norm = normalize(w)
        if norm in STOPWORDS:
            continue
        out.append(ABBREVIATIONS.get(norm, w))
    return out


def word_overlap(osm_name: str, words: list[str]) -> int:
    """Count of significant words shared between the OSM name (including its
    official_name alias, since CTT-style qualifiers like "Vila de" often only
    appear there) and the CTT words — order-independent, since either side
    can carry extra words the other doesn't.
    """
    osm_words = {normalize(w) for w in re.findall(r"[A-Za-zÀ-ÿ]+", osm_name)}
    target = {normalize(w) for w in words}
    return len(osm_words & target)


def best_superset_match(elements: list[dict], words: list[str]) -> dict | None:
    def overlap(e: dict) -> int:
        tags = e.get("tags", {})
        names = " ".join(filter(None, [tags.get("name", ""), tags.get("official_name", "")]))
        return word_overlap(names, words)

    candidates = [e for e in elements if overlap(e) >= 1]
    if not candidates:
        return None

    def rank(e: dict) -> tuple[int, int, int]:
        place = e.get("tags", {}).get("place", "")
        place_rank = PLACE_TYPE_RANK.index(place) if place in PLACE_TYPE_RANK else len(PLACE_TYPE_RANK)
        extra_words = abs(len(re.findall(r"[A-Za-zÀ-ÿ]+", e["tags"]["name"])) - len(words))
        return (-overlap(e), place_rank, extra_words)

    candidates.sort(key=rank)
    return candidates[0]


def main() -> None:
    table: dict[str, dict] = json.loads(OUTPUT_PATH.read_text(encoding="utf-8"))
    cp4_to_locality = load_cp4_localities()
    missing = {cp4: loc for cp4, loc in cp4_to_locality.items() if cp4 not in table}
    print(f"{len(missing)} CP4 entries remaining.", file=sys.stderr)

    resolved = 0
    still_missing = []

    for cp4, locality in sorted(missing.items()):
        words = significant_words(locality)
        if not words:
            still_missing.append(cp4)
            continue

        match = None
        # Longest word first — short common words (Vila, Santa, Sao) make
        # weak anchors and return huge, slow candidate sets.
        for anchor in sorted(set(words), key=len, reverse=True):
            print(f"{cp4} ({locality}): searching by anchor word '{anchor}'...", file=sys.stderr)
            query = (
                "[out:json][timeout:60];"
                'area["ISO3166-1"="PT"]->.pt;'
                f'node["place"]["name"~"{accent_flexible(anchor)}",i](area.pt);'
                "out center;"
            )
            elements = overpass_retrying(query)
            match = best_superset_match(elements, words) if elements else None
            if match is not None:
                break
            time.sleep(3.5)

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
        print(f"{len(still_missing)} CP4 prefixes remain unmatched (no OSM place node found):", file=sys.stderr)
        for cp4 in still_missing:
            print(f"  - {cp4}: {cp4_to_locality[cp4]}", file=sys.stderr)


if __name__ == "__main__":
    main()
