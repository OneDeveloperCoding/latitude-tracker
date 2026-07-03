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

import re
import sys
import time

from cp4_common import (
    REGION_BBOX,
    accent_flexible,
    load_cp4_localities,
    load_table,
    normalize,
    overpass_retrying,
    region_hint,
    save_table,
    significant_words,
)

REQUEST_DELAY_SECONDS = 3.5

ISLAND_HINTS = {
    "madeira": "madeira",
    "sao miguel": "azores",
    "sao jorge": "azores",
    "acores": "azores",
}

SUFFIX_CODE_RE = re.compile(r"^(?P<base>.+?)\s+(?P<code>[A-Z]{2,4})$")
PARENTHETICAL_RE = re.compile(r"^(?P<base>.+?)\s*\((?P<qualifier>[^)]+)\)$")


def name_pattern(base: str) -> str:
    return ".*".join(accent_flexible(w) for w in significant_words(base))


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


def resolve_plain(locality: str) -> dict | None:
    query = (
        "[out:json][timeout:60];"
        'area["ISO3166-1"="PT"]->.pt;'
        f'node["place"]["name"~"^({name_pattern(locality)})$",i](area.pt);'
        "out center;"
    )
    elements = overpass_retrying(query)
    return elements[0] if elements else None


def main() -> None:
    table = load_table()
    cp4_to_locality = load_cp4_localities()
    missing = {cp4: loc for cp4, loc in cp4_to_locality.items() if cp4 not in table}
    print(f"{len(missing)} CP4 entries remaining.", file=sys.stderr)

    resolved = 0
    still_missing = []

    for cp4, locality in sorted(missing.items()):
        paren = PARENTHETICAL_RE.match(locality)
        suffix = SUFFIX_CODE_RE.match(locality)

        if paren:
            print(f"{cp4} ({locality}): resolving by region qualifier '{paren['qualifier']}'...", file=sys.stderr)
            match = resolve_by_region(paren["base"], paren["qualifier"], cp4)
        elif suffix:
            print(f"{cp4} ({locality}): resolving by concelho code '{suffix['code']}'...", file=sys.stderr)
            match = resolve_by_concelho_code(suffix["base"], suffix["code"])
        else:
            print(f"{cp4} ({locality}): no suffix pattern, retrying plain fuzzy match...", file=sys.stderr)
            match = resolve_plain(locality)

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

        time.sleep(REQUEST_DELAY_SECONDS)

    save_table(table)
    print(f"\nResolved {resolved} more entries. Total now: {len(table)}/{len(cp4_to_locality)}.", file=sys.stderr)
    if still_missing:
        print(f"{len(still_missing)} CP4 prefixes remain unmatched:", file=sys.stderr)
        for cp4 in still_missing:
            print(f"  - {cp4}: {cp4_to_locality[cp4]}", file=sys.stderr)


if __name__ == "__main__":
    main()
