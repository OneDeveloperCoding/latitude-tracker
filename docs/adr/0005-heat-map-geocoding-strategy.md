# Heat map geocoding strategy: Nominatim + layered cache + background warm-up

The SalesHeatMap geocodes Portuguese postal-code prefixes to map coordinates using the Nominatim OpenStreetMap API, with a two-layer cache (in-memory L1 + SharedPreferences L2) and a background warm-up triggered on every data load.

## Decision

**Grouping:** Postal codes are reduced to their 4-digit locality prefix (e.g. `3000-550` → `3000`) before geocoding. This groups all sales in the same town under one marker and keeps the geocoding request count proportional to unique localities, not unique postal codes.

**Geocoding provider:** Nominatim (`nominatim.openstreetmap.org`). Free, no API key, covers all Portuguese localities.

**Rate limiting:** A 1-second delay between requests is enforced inside `_fetchFromNominatim`. Cached lookups bypass the delay entirely.

**Cache TTL:**
- Successful geocodes: 180 days (localities don't move)
- Failed lookups (Nominatim returned no result): 7 days (retry eventually in case of transient error)
- Cache key is versioned (`v2`) — bumping the version invalidates stale entries that predate the `locality` field addition without manual cache clearing.

**Background warm-up:** `GeocodingWarmUp` (in `lib/features/heat_map/services/`) listens to `SalesStore.state` and calls `GeocodingService.warmUp()` on every `StoreLoaded` emission. `MainNav` attaches and detaches the listener as part of its store lifecycle. Prefixes are extracted via `HeatMapService.localityPrefix()` — the same regex-validated extraction used at runtime — so the warm-up primes exactly the cache keys that `GeographicSalesService.buildRanking` and `HeatMapService.buildPoints` will request. By the time the user navigates to GeographicSalesView, most prefixes are already cached and the screen opens instantly.

## Considered options

**Google Maps Geocoding API:** Accurate and well-supported, but requires an API key with billing enabled. Unacceptable for a private app with no revenue model.

**`postcodes.io`:** UK-only.

**No cache, geocode on demand:** The Nominatim rate limit (1 req/sec) makes this unusable when a seller has sales across 20+ localities — the map would take 20+ seconds to load every time.

**Client-side static lookup table (postal code prefix → lat/lon):** Would be fast and offline, but Portugal has ~4,700 4-digit prefixes. Maintaining an embedded table is fragile; Nominatim is authoritative.

## Trade-offs to watch

- Nominatim's usage policy requires a valid `User-Agent` and forbids heavy automated use. At this app's scale (well under 100 geocoding requests per session) this is fine.
- If Nominatim ever starts returning incorrect results for a locality, the 180-day TTL means the bad entry persists until it expires or the cache key is bumped.
