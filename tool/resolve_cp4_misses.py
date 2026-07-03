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

import re
import sys
import time

from cp4_common import (
    PLACE_TYPE_RANK,
    REGION_BBOX,
    accent_flexible,
    load_cp4_localities,
    load_table,
    overpass_retrying,
    region_hint,
    save_table,
    significant_words,
)

BATCH_SIZE = 5
REQUEST_DELAY_SECONDS = 3.0
MAX_RETRIES = 3


def wildcard_pattern(name: str) -> str | None:
    words = significant_words(name)
    if not words:
        return None
    return ".*".join(accent_flexible(w) for w in words)


def build_batch_query(patterns: list[str]) -> str:
    alternation = "|".join(f"({p})" for p in patterns)
    return (
        "[out:json][timeout:90];"
        'area["ISO3166-1"="PT"]->.pt;'
        f'node["place"]["name"~"^({alternation})$",i](area.pt);'
        "out center;"
    )


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
    table = load_table()
    cp4_to_locality = load_cp4_localities()

    missing = {cp4: locality for cp4, locality in cp4_to_locality.items() if cp4 not in table}
    print(f"{len(missing)} CP4 entries still missing, attempting fuzzy resolution...", file=sys.stderr)

    pattern_by_cp4: dict[str, str] = {}
    for cp4, locality in missing.items():
        pattern = wildcard_pattern(locality)
        if pattern:
            pattern_by_cp4[cp4] = pattern

    cp4_list = list(pattern_by_cp4.items())
    resolved = 0
    still_missing: list[str] = []

    for i in range(0, len(cp4_list), BATCH_SIZE):
        batch = cp4_list[i : i + BATCH_SIZE]
        patterns = [p for _, p in batch]
        print(f"Fuzzy batch {i // BATCH_SIZE + 1} ({len(batch)} entries)...", file=sys.stderr)

        elements = overpass_retrying(build_batch_query(patterns), attempts=MAX_RETRIES)
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
        time.sleep(REQUEST_DELAY_SECONDS)

    save_table(table)

    print(f"\nResolved {resolved} more entries. Total now: {len(table)}/{len(cp4_to_locality)}.", file=sys.stderr)
    if still_missing:
        print(f"{len(still_missing)} CP4 prefixes remain unmatched (will be excluded from the heat map):", file=sys.stderr)
        for cp4 in sorted(still_missing):
            print(f"  - {cp4}: {cp4_to_locality[cp4]}", file=sys.stderr)


if __name__ == "__main__":
    main()
