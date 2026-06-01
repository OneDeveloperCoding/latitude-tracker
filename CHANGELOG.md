# Changelog

## [Unreleased]

### Features
- Structured buyer addresses: street name, house number, fraction (optional), delivery notes (optional) — replaces single street blob
- Portuguese postal code auto-fill: entering a full `XXXX-XXX` code fetches city + street from GeoAPI.pt, with 180-day local device cache; non-PT addresses remain free text
- App icon: custom icon replacing Flutter default, generated via `flutter_launcher_icons` for all density buckets + adaptive icon (Android 8+)
- App display name: "Latitude Tracker" (was "latitude_tracker" in launcher)
- APK filename in GitHub Releases: `latitude-tracker.apk` (was `app-release.apk`)

### Fixes
- Demo mode top gap: `MediaQuery.removePadding(removeTop: true)` applied to inner screens when demo banner is active, removing double status-bar padding
- Shopping list cards now navigate to the respective sale detail on tap

### Architecture
- `SalesStore` + `BuyersStore` shared singleton streams — one Firestore WebSocket per collection regardless of screens mounted; state typed via `StoreState<T>` sealed class (`StoreLoading` / `StoreLoaded` / `StoreError`)
- `SaleUrgency` service: single source of truth for urgency level, blocker reasons, and days-until-scheduled — replaces three divergent private implementations
- `SaleGrouper.byWeek()`: timeline grouping extracted as a pure function
- Abstract `SaleRepository` / `BuyerRepository` with factory constructors — DemoMode routing happens once at construction, not in every method body
- `Sale.deriveAssemblyStatus()` + `Sale.withUpdatedComponents()`: component auto-ready rule lives on the model, applied consistently across sale detail and new sale form
- Firebase Crashlytics: automatic crash reporting with email alerts; zone mismatch and hero tag collision bugs surfaced and fixed

## [1.0.0] — 2026-06-01

Initial stable release.

### Features
- Sales tracking: create, edit, delete sales with items, photos, assembly status, component checklist, payment, shipment, NIF, and notes
- Buyers: profiles with addresses, purchase history, ranking metrics, unpaid balances
- Dashboard: period selector (yearly/monthly/weekly), revenue cards, action counts (unpaid, pending shipment, assembly not ready, NIF required, overdue) — each tapping to a dedicated view
- Sale card progress path: three-node Assembly → Payment → Shipment bar spanning full card width; left accent bar (red/amber) for urgency; attention badges with tap-to-sheet detail
- Shopping list: aggregated view of all unacquired components across open sales
- NIF receipts: pending AT submissions with one-tap filed/unfiled toggle
- Sales heat map: geographic view by postal code locality prefix via Nominatim geocoding
- Archive: export/import year data as JSON with photo URL preservation
- Demo mode: 255 pre-seeded sales across 18 months, tutorial bottom sheet on first entry
- Language toggle: Portuguese (default) / English, persisted across sessions
- Settings: sign out, export, import, delete year, language, app version
