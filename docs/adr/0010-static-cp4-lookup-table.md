---
status: accepted, supersedes ADR-0005
---

# Static CP4 lookup table replaces Nominatim geocoding

The heat map's `GeocodingService` called Nominatim over the network to resolve each 4-digit postal-code prefix (CP4) to a coordinate. ADR-0005 explicitly rejected a bundled static table at the time, estimating ~4,700 prefixes as too large to maintain. Portugal actually has ~900 active CP4 prefixes, and this app is heading toward being open-sourced (v1.7 milestone), which changes the calculus: shipping a live Nominatim dependency in a public repo is more scrutiny than a private app, and — critically — Nominatim's usage policy discourages bulk/scripted harvesting and redistribution of results, which rules out generating the table by simply running the existing geocoder once. We replace the network call with a table compiled offline by joining two openly-licensed sources: CTT's official CP4 → locality name data, and OSM/Overpass settlement (`place=*`) centroids matched by locality name — OSM's postal-code tagging alone is too sparse in Portugal to query directly, but its settlement/place nodes are well maintained. The compiled table ships as a bundled JSON asset; `GeocodingWarmUp` and the SharedPreferences cache layers are removed entirely since there is no more network path to warm up or cache misses to retry.

## Considered options

**One-time Nominatim harvest:** Reuses the existing geocoding code and matches current accuracy exactly, but conflicts with Nominatim's ToS against bulk harvesting for redistribution — unacceptable for a repo being prepared to go public.

**OSM/Overpass `addr:postcode` tags directly:** Legally clean (ODbL) but Portuguese address-level postal-code tagging in OSM is too sparse/inconsistent to build a complete 900-entry table from directly.

**CTT data alone:** Authoritative for CP4 → locality name, but the dataset has no coordinates — it's a street/locality registry, not a geocoded one.

## Trade-offs to watch

- New or restructured CP4 prefixes (CTT rarely does this) require manually regenerating the table; there is no runtime fallback or retry path anymore.
- The OSM+CTT name-matching step (disambiguating same-named localities in different concelhos, localities with no OSM place node) needs care during implementation — tracked as a research task on the issue rather than decided here.
