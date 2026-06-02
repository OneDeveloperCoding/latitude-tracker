# Roadmap

Planned improvements and features for latitude-tracker, roughly in priority order.

---

## Heat Map

**Performance overhaul + richer interaction**

The heat map currently takes too long to load. The bottleneck is likely Nominatim geocoding — one HTTP request per unique locality prefix, rate-limited and sequential. Options to investigate:

- Cache geocoding results in Firestore (per-user) so repeat loads are instant and don't re-hit Nominatim
- Batch or parallelise requests where rate limits allow
- Replace Nominatim with a faster/paid geocoding provider (e.g. Google Maps Geocoding API — already on Firebase Blaze)
- Pre-compute and store `(postalPrefix → LatLng)` on sale write rather than at display time
- Show a progressive loading state (render known points first, fill in the rest)

**Richer map bubbles**

Map markers currently only show a heat intensity dot. Each bubble should be more informative and actionable:

- Tap a bubble to open a bottom sheet listing the sales for that locality (buyer name, item, status)
- Tapping a sale in the sheet navigates to its detail screen
- Show sale count and total revenue as a label on or near the bubble
- Differentiate bubble colour/size by revenue or sale count, not just density

---

## Monitoring & Analytics

**Firebase Performance Monitoring + Analytics**

Add visibility into app performance and usage patterns.

- Auto screen tracking via `FirebaseAnalyticsObserver` on the router
- Performance traces around key operations (e.g. sales list load)
- Key events: `sale_created`, `filter_applied`

Already on Firebase (Firestore), so no new accounts needed. Packages: `firebase_performance`, `firebase_analytics`.

---

## Testing

**Tier 2 — Repository tests (Firestore-backed)**

Unit-test `SaleRepository` and `BuyerRepository` against a real in-memory Firestore instance.

- Add `fake_cloud_firestore` to `dev_dependencies`
- Test CRUD operations: create, read, update, delete
- Test stream emissions (`watchSale`, `watchAddresses`) on data changes
- Test `getSalesForBuyer` filtering

**Tier 3 — Widget tests**

Smoke-test key screens to catch widget-tree regressions.

- `SalesListScreen`: renders with empty store, renders with a loaded list
- `_SaleCard`: correct accent bar on urgency, correct badges (NIF, urgency)
- `BuyerDetailScreen`: tabs present, info section above tabs
- `AddressFormFields`: postal code lookup triggers spinner, single-street auto-fills, multi-street shows picker

---
