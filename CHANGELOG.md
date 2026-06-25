# Changelog

## [Unreleased]

---

## [1.9.0] — 2026-06-25

### Features
- Dashboard "Ready to assemble" card: counts and links to sales where all components are acquired and assembly hasn't started yet
- Dashboard "Needs materials" counter fixed to cover only sales with missing components or `waitingForMaterials` status (previously counted all non-ready assembly states)

### Fixes
- Ship workflow: `gh pr list` returned the string `"null"` on an empty result set, causing PR creation to be skipped on every first run; fixed with an explicit length guard

### Infrastructure
- Ship workflow added: single `workflow_dispatch` trigger that merges `develop → main`, waits for CI, and calls the Release workflow — one-click releases from GitHub Actions
- Release workflow now supports `workflow_call` so Ship can invoke it as a reusable step

### Chores
- `Sale.needsMaterials` getter extracted as single source of truth for the missing-components predicate used by the dashboard counter

---

## [1.8.0] — 2026-06-25

### Features
- Google Sign-In added alongside email/password; a "Connect Google account" tile in Settings → Account links the seller's Google credentials to her existing Firebase account via `linkWithCredential`, preserving the UID and all data; both methods coexist permanently with email/password kept as fallback
- In-app update checker: app checks GitHub Releases on every cold start and shows an "update available" tile in Settings → App when a newer version is published; tapping downloads and installs the APK directly
- Sale and Repair detail screens default to read-only; a FAB switches to edit mode — reduces accidental edits and declutters the AppBar
- RepairCard redesigned with the same tri-indicator strip as SaleCard (payment · work status · return delivery); demo mode guards added to block Firestore writes in demo mode
- Shipped date shown on SaleCard when a `shipping`-type Shipment has been marked as shipped; Repair detail section order aligned with Sale detail conventions

### Fixes
- Portuguese label for `in_progress` corrected from "Em curso" to "Em progresso" for both `AssemblyStatus` and `RepairStatus`
- Sale and Repair item count label simplified to "+ N" (was "+ N more" / "+ N mais")

### Infrastructure
- CI restore step now base64-decodes both `FIREBASE_OPTIONS_DART` and `GOOGLE_SERVICES_JSON` before running tests or builds
- `firebase.json` added to `.gitignore`; restored from CI secret in the release workflow
- Personal info and internal config details removed from README
- Release workflow now bakes version into APK via `--build-name`/`--build-number` flags instead of committing a pubspec change — no direct push to `main` required; tag push only

### Chores
- Completed migration from `flutter_lints` to `very_good_analysis` — all ~50 additional lint rules are now active; `analysis_options.yaml` only disables `public_member_api_docs` (not applicable for a private app). Fixes applied: `on Object catch` on all broad catch clauses, `unawaited()` on 53 fire-and-forget futures, `doc.data()!` on four model deserialisers, named bool params on three methods, 80-char line wrapping throughout.

---

## [1.7.0] — 2026-06-17

### Features
- Inline RepairStatus picker on Repair detail screen — status can be changed directly in the detail view without navigating away; stale optimistic state is cleared on external Firestore update
- Buyer detail screen now shows the buyer's full repair history alongside their sale history; sales filter state is preserved across tab switches
- `ComponentItem` now has a quantity field; `AssemblyStatus` is set manually rather than derived from checklist completion

### Fixes
- `BuyerDetailScreen` pop guarded against a double-pop race condition that could crash navigation when the screen was dismissed while a stream update was in flight
- `SafeArea` added to `SalesRepairsTabScreen` so content clears the status bar correctly

---

## [1.6.0] — 2026-06-14

### Features
- ComponentChecklist items now support photos and notes — each checklist item can have an attached photo and a free-text note alongside its completion state

### Fixes
- `AddressesStore` removed — it held a `collectionGroup` query that triggered Firestore permission-denied errors on accounts without the rule, causing a silent sign-out; buyer addresses are now fetched per-buyer inside their detail screen only
- `_AddressDisplay` converted to `StatefulWidget` — the previous stateless form recreated the Firestore listener on every parent rebuild, causing unnecessary churn
- Repair received-date moved into the Item section card and its format and icon aligned with Sale detail conventions
- Map icon on "Open in Maps" buttons replaced with a location-pin icon to match platform conventions
- Scheduled-date chip on the sale card now uses `Icons.event` instead of the 📅 emoji — consistent with the rest of the icon system

---

## [1.5.0] — 2026-06-08

### Features
- Dark mode toggle added to Settings — persists across sessions via SharedPreferences

### Performance
- `SalesListScreen`: buyer lookup, `DateFormat`, and year/month values are now computed once per build cycle instead of per-item — eliminates redundant work on large lists
- `AnalyticsScreen`: analytics computation is cached in widget state and only re-runs when data changes

### Fixes
- `renameCategory` now runs its Firestore batch operations sequentially — reduces partial-failure blast radius when a rename touches many documents

### Architecture
- `StreamStore<T>` generic base class extracted — `SalesStore` and `BuyersStore` now share a single implementation instead of duplicating stream subscription logic
- `BasePhotoService` extracted — removes duplication between the sale and repair photo services
- `ArchiveService.importArchive` now routes writes through the repository layer instead of accessing Firestore directly
- `DashboardStats` split: analytics-only methods moved to a dedicated class, keeping `DashboardStats` focused on dashboard concerns
- Sale and buyer IDs now generated with the `uuid` package instead of `FirebaseFirestore.instance.collection().doc().id` — removes an unnecessary Firestore round-trip

### Testing
- Pure-logic test files migrated from `flutter_test` to `package:test` — faster execution and no Flutter framework dependency for tests that don't need it

### Infrastructure
- Lint rules expanded with targeted `flutter_lints` additions to catch common patterns specific to this codebase
- Release signing, version tracking, and CI workflows unified into a single consistent pipeline
- Naming fixes: `SaleFilterLabel` removed, `AssemblyStatusUI` centralised, `BuyerStats` updated to single-pass computation; `AssemblyStatusUI` extension applied across `SaleDetailScreen` and `ShoppingListScreen`

---

## [1.4.0] — 2026-06-07

### Features
- Buyer addresses are now tappable links — tapping opens Google Maps with the formatted address pre-filled, available from both Sale detail and Buyer detail screens

### Fixes
- Accessibility: icon-only buttons now carry semantic labels; touch targets meet minimum size; `CircleAvatar` buyer initials are wrapped in `Semantics`
- Category hide list no longer accumulates duplicate entries when `hideCategory` is called more than once for the same category

### Testing
- Unit tests added for `SaleGrouper`, `HeatMapService`, and `Repair` model (null-safe fields, enum fallbacks, sub-map defaults)
- `CategoryService` test fixed to use injected repositories instead of relying on constructor-time snapshots

### Architecture
- `CategoryService` now fetches the hidden-category list itself rather than accepting a caller-supplied snapshot, eliminating stale-data bugs

### Infrastructure
- `bump-and-tag` workflow now restores `firebase_options.dart` and `google-services.json` from repository secrets before building the APK

---

## [1.3.1] — 2026-06-06

### Features
- Repair detail: quick-action buttons to advance `ReturnDelivery` status without opening the edit form
- `BuyerRepository.watchBuyer(id)` stream — `BuyerDetailScreen` now reacts to remote buyer changes in real time

### Performance
- Thumbnail `Image.network` calls supply `cacheWidth`/`cacheHeight` — reduces GPU texture memory for list views
- `BuyersListScreen` ranked-view rebuild reduced from O(buyers × sales) to O(sales) — eliminates quadratic scroll jank

### Fixes
- Form and label UX hardening across multiple screens (label capitalisation, keyboard type, autofill hints)
- Nominatim geocoding errors no longer cached as misses — a server error no longer permanently suppresses map links for an address
- Unsaved-changes `PopScope` guard added to `BuyerFormScreen` and `BuyerAddressFormScreen`
- Detail screens (`SaleDetailScreen`, `BuyerDetailScreen`, `RepairDetailScreen`) now pop automatically when their stream emits `null` after deletion
- `StoreErrorWidget` with retry action wired into all store-driven screens
- `RepairDetailScreen` converted to `StatefulWidget` with stream moved to `initState` — prevents stream re-subscription on every rebuild
- All UI strings and model fields renamed from "order/encomenda" to "sale/venda" for consistency with the domain language

### Architecture
- `UrgencyReason` icon and colour mapping moved from `SaleUrgency` business logic into a UI-layer extension

---

## [1.3.0] — 2026-06-06

### Features
- **Repairs**: new feature to track repair jobs — linked to a buyer or standalone free-text contact; fields include item description, category, problem, labour cost, materials cost, payment, and return delivery; full list, detail, and edit screens
- Repair detail: quick-action buttons to advance `RepairStatus` through the workflow
- **Category maintenance**: rename, hide, and delete item categories from Settings
- **Archive analytics**: import a JSON archive and view yearly/monthly revenue trends in the Analytics screen
- **Hand delivery** added as a third delivery type alongside shipping and pickup
- **Revolut** and **PayPal** added as payment methods with brand colours
- Buyer sale picker replaced with a buyer-scoped sheet — only that buyer's existing sales are shown when linking a repair
- Master-detail split view for the Sales list on tablets (600 dp+)
- Demo tour revamped as a 7-page paged walkthrough with illustrations
- Analytics screen: `InsightsCard` and `TrendsScreen` merged into a single `AnalyticsScreen` accessed from the revenue card; standalone entry card removed
- Sort UI in the Sales filter sheet compacted; Buyers ranking metric picker moved into the tune sheet
- Search toolbars in Sales and Buyers screens collapse when scrolling down

### Performance
- `DashboardStats.compute()` 8-pass filter loop replaced with a single accumulator

### Fixes
- Global store lifecycle hardened: dispose race, `StoreLoading` deadlock, and stale auth data after sign-out resolved
- Stores no longer stuck permanently in `StoreError` after the first stream error — error is surfaced and stream continues
- Auth-revocation handling hardened; `currentUser!` force-unwraps replaced with null-guarded throws
- `fromFirestore`/`fromMap` deserialisers guarded against null fields and unknown enum strings across all models
- Crashlytics wired to store stream errors, UI write catch blocks, and navigation guards — no more silent failures
- Firebase config files (`firebase_options.dart`, `google-services.json`) removed from version control; CI restores them from repository secrets

### Architecture
- Abstract `SaleRepository` / `BuyerRepository` with factory constructors routing to Firestore or in-memory implementation based on `DemoMode`
- `SalesStore` + `BuyersStore`: shared singleton streams, one Firestore WebSocket per collection; state exposed as `StoreState<T>` sealed class

### Infrastructure
- `bump-and-tag` CI workflow: auto-detects version bump from conventional commits; creates tag and builds APK in a single run
- `flutter test` step added to the release workflow — APK build blocked if any test fails

---

## [1.2.0] — 2026-06-04

### Features
- Dashboard period control replaced with a scrollable 6-month chip row — the dashboard now operates at monthly granularity only; yearly/weekly modes are available exclusively in the AnalyticsScreen
- Dashboard action section redesigned as grouped full-width rows (coloured icon, label, count, chevron); actions split into three labelled sections: **Money** (Unpaid, Overdue, NIF required), **Production** (Assembly not ready, Pending shipment, In transit), **Planning** (Upcoming scheduled) — seven rows total, up from five
- `InsightsCard` and `TrendsScreen` merged into a single **AnalyticsScreen** accessed from an insights icon button embedded in the revenue card; the standalone entry card at the bottom of the Dashboard is removed
- Search bars unified across Sales list, Buyers list, and Unpaid Balances screens — consistent placement and behaviour

### Fixes
- Error handling audit: non-fatal Crashlytics recording wired up consistently across all repository and service layers

### Infrastructure
- Flutter upgraded to 3.44.1 (required by `image_picker` Dart SDK constraint)

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
