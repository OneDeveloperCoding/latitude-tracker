# Changelog

## [1.1.0] — 2026-06-02

### Features
- Structured buyer addresses: street name, house number, fraction (optional), delivery notes (optional) — replaces single street blob
- Portuguese postal code auto-fill: entering a full `XXXX-XXX` code fetches city + streets from GeoAPI.pt, with 180-day local device cache; single-match auto-fills the street field, multiple matches show a picker sheet; non-PT addresses remain free text
- Address city field relabelled "Locality / Localidade" to match Portuguese postal addressing convention and the API's own field name
- Buyer detail: tabbed layout with "History" and "Addresses" tabs; buyer info card (contact details) pinned above the tab bar
- Login screen: autofill support — email and password hints let password managers fill credentials; successful sign-in triggers the OS save prompt
- Sales list: ℹ button in AppBar opens the progress path legend — replaces the unreliable hidden footer tap
- Dashboard action cards redesigned as compact full-width rows (coloured icon, label, count, chevron) — all five fit on screen without scrolling
- Demo tutorial: eighth tip added for the heat map view
- App icon: custom icon replacing Flutter default; all density buckets + adaptive icon (Android 8+)
- App display name: "Latitude Tracker" (was "latitude_tracker" in launcher)
- APK filename in GitHub Releases: `latitude-tracker.apk` (was `app-release.apk`)

### Fixes
- Crash ("Stream has already been listened to"): streams now created in `initState`, not in `build()`; affects `SaleDetailScreen`, `BuyerDetailScreen._AddressesList`, `BuyerPickerScreen`
- Crash ("Child ordering assertion"): `BuyerDetailScreen` converted to `StatefulWidget` with a stable `_buyerFuture` — prevents `FutureBuilder` reset on every parent rebuild which dismounted the inner `ListView` and corrupted render child order
- Crash ("Null check in paint"): downstream consequence of the child ordering crash; resolved by the same fix
- Postal code street lookup: API response was misread — streets are in `partes[*].Artéria`, not a top-level `Artéria`; auto-fill was silently returning empty on every lookup
- Dashboard action counts (unpaid, pending shipment, assembly not ready, NIF required, overdue) are now global (current state) rather than period-scoped — counts now match what the destination screens show
- Demo mode top gap: `MediaQuery.removePadding(removeTop: true)` applied when demo banner is active
- Shopping list cards now navigate to the respective sale detail on tap

### Testing
- 55 unit tests covering `SaleUrgency` (urgency level week boundaries, all blocker reasons, days-until-scheduled), `SaleFilter` (all 9 variants including date-sensitive overdue boundary), `Sale.deriveAssemblyStatus` (7 cases including empty-component edge case), and `BuyerStats.compute` (totals, balance, average, last purchase)
- `flutter test` step added to the GitHub Actions release workflow — APK build is blocked if any test fails

### Architecture
- `DashboardStats.compute()`: 8-pass filter loop replaced with a single accumulator — O(n) instead of O(8n)
- `NifPendingScreen`: buyers-by-id map cached in state, rebuilt only on store change
- `SaleGrouper.byWeek()`: week boundary dates hoisted out of per-sale `_weekKey()` into the outer call
- `_BuyerSalesSection`: replaced per-screen Firestore stream with `SalesStore` — eliminates one redundant WebSocket per open buyer detail screen
- `BuyersListScreen`: alphabetical, grouped, and ranked view lists pre-computed on store change
- `SaleUrgency`: converted to `extension on Sale` — `sale.urgencyLevel()` / `sale.urgencyReasons()` / `sale.daysUntilScheduled()`
- `SalesListScreen`: filter + group result cached in state; `_TimelineView` accepts pre-grouped map
- `_SaleCard`: `urgencyReasons()` computed once per build, passed to `_AttentionBadges`
- `SalesStore` + `BuyersStore`: shared singleton streams, one Firestore WebSocket per collection; state via `StoreState<T>` sealed class
- Abstract `SaleRepository` / `BuyerRepository` with factory constructors — DemoMode routing at construction time
- `Sale.deriveAssemblyStatus()` + `Sale.withUpdatedComponents()`: component auto-ready rule on the model
- Firebase Crashlytics: automatic crash reporting with email alerts

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
