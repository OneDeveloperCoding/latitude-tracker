#!/usr/bin/env python3
"""One-time generator for assets/data/cp4_coordinates.json.

Not part of the app — run manually by a developer whenever CTT restructures
postal codes (rare). Joins two openly-licensed sources instead of geocoding
live, per docs/adr/0010-static-cp4-lookup-table.md:

  1. CTT postal code data (PDDL-licensed), via the centraldedados/codigos_postais
     mirror, for the CP4 -> locality name mapping. For each CP4 prefix, the
     locality name with the most matching rows in the source data is taken as
     the representative name (a CP4 can span several small localities; the
     dominant one is what a human would call "the town").
  2. OpenStreetMap Overpass API (ODbL-licensed), queried by locality name
     restricted to Portugal, for the settlement centroid. Ambiguous name
     matches are resolved by preferring larger place types
     (city > town > village > hamlet) and are logged for manual review.

Run the resolve_cp4_*.py follow-up passes afterwards to fill in the misses
this exact-name pass can't match (abbreviations, missing prepositions,
accent drift, CTT disambiguation suffixes).

Usage: python3 tool/generate_cp4_table.py
"""

from __future__ import annotations

import re
import sys
import time

from cp4_common import (
    PLACE_TYPE_RANK,
    load_cp4_localities,
    overpass_retrying,
    save_table,
)

BATCH_SIZE = 15
REQUEST_DELAY_SECONDS = 1.5
MAX_RETRIES = 3


def build_batch_query(names: list[str]) -> str:
    escaped = "|".join(re.escape(n) for n in names)
    return (
        '[out:json][timeout:60];'
        'area["ISO3166-1"="PT"]->.pt;'
        f'node["place"]["name"~"^({escaped})$",i](area.pt);'
        "out center;"
    )


def best_match(elements: list[dict], name: str) -> dict | None:
    candidates = [
        e for e in elements if e.get("tags", {}).get("name", "").lower() == name.lower()
    ]
    if not candidates:
        return None
    if len(candidates) == 1:
        return candidates[0]

    def rank(e: dict) -> int:
        place = e.get("tags", {}).get("place", "")
        return PLACE_TYPE_RANK.index(place) if place in PLACE_TYPE_RANK else len(PLACE_TYPE_RANK)

    candidates.sort(key=rank)
    best_rank = rank(candidates[0])
    tied = [c for c in candidates if rank(c) == best_rank]
    if len(tied) > 1:
        print(f"  AMBIGUOUS: '{name}' has {len(tied)} equally-ranked matches, taking first.", file=sys.stderr)
    return tied[0]


def geocode_localities(names: set[str]) -> dict[str, tuple[float, float, str]]:
    """Returns {CTT locality name: (lat, lon, OSM display name)} via batched
    Overpass queries. The OSM display name is properly cased (e.g. "Sintra")
    unlike the CTT source, which is all-caps ("SINTRA") — used for the UI.
    """
    sorted_names = sorted(names)
    coords: dict[str, tuple[float, float, str]] = {}
    misses: list[str] = []

    for i in range(0, len(sorted_names), BATCH_SIZE):
        batch = sorted_names[i : i + BATCH_SIZE]
        print(f"Geocoding batch {i // BATCH_SIZE + 1} ({len(batch)} localities)...", file=sys.stderr)

        elements = overpass_retrying(
            build_batch_query(batch), attempts=MAX_RETRIES, base_wait=REQUEST_DELAY_SECONDS * 3
        )
        if elements is None:
            print(f"  giving up on batch after {MAX_RETRIES} attempts: {batch}", file=sys.stderr)
            misses.extend(batch)
            continue

        for name in batch:
            match = best_match(elements, name)
            if match is None:
                misses.append(name)
            else:
                display_name = match.get("tags", {}).get("name", name)
                coords[name] = (match["lat"], match["lon"], display_name)
        time.sleep(REQUEST_DELAY_SECONDS)

    if misses:
        print(f"\n{len(misses)} localities had no OSM match:", file=sys.stderr)
        for name in misses:
            print(f"  - {name}", file=sys.stderr)

    return coords


def main() -> None:
    print("Downloading CTT postal code data...", file=sys.stderr)
    cp4_to_locality = load_cp4_localities()
    print(f"Found {len(cp4_to_locality)} distinct CP4 prefixes.", file=sys.stderr)

    unique_localities = set(cp4_to_locality.values())
    print(f"{len(unique_localities)} unique locality names to geocode.", file=sys.stderr)

    coords = geocode_localities(unique_localities)

    table = {}
    for cp4, locality in sorted(cp4_to_locality.items()):
        if locality in coords:
            lat, lon, display_name = coords[locality]
            table[cp4] = {"lat": lat, "lng": lon, "locality": display_name}

    save_table(table)

    print(f"\nWrote {len(table)}/{len(cp4_to_locality)} CP4 entries.", file=sys.stderr)


if __name__ == "__main__":
    main()
