# Latitude Tracker

Private Android app for tracking sales, buyers, shipments, and payments for a handmade accessories business in Portugal.

## Stack

- Flutter (Android only, SDK needed)
- Firebase **Blaze** plan required (Storage used for photos)
  - Firestore (eur3 — Europe multi-region)
  - Storage (europe-west1)
  - Auth (email/password, single account)
- Key packages: `flutter_map` + `latlong2` (heat map), `image_picker` (photos), `share_plus` + `file_picker` (archive export/import), `shared_preferences` (language preference + postal code cache), `flutter_localizations` (PT/EN Material widget translations), `intl` (date formatting locale), `firebase_crashlytics` (crash reporting), `http` (postal code lookup)

## Local setup

Requires `direnv` — `FLUTTER_ROOT`, `ANDROID_HOME`, and `PATH` are activated automatically on `cd` via `.envrc`.

```bash
cd ~/deving/projects/latitude-tracker
flutter pub get
flutter run
```

### Firebase configuration

`lib/firebase_options.dart` and `android/app/google-services.json` are committed to the repo (private repo — safe). If you ever need to regenerate `firebase_options.dart`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Select the existing Firebase project and choose Android only.

## Releases

APK builds are automated via GitHub Actions (`.github/workflows/release.yml`). To cut a release:

```bash
# 1. Update CHANGELOG.md — add a new ## [x.x.x] section
# 2. Bump version in pubspec.yaml  e.g. version: 1.1.0+2
git commit -m "Release v1.1.0"
git tag v1.1.0 && git push --tags
```

GitHub Actions builds the APK and attaches it to a GitHub Release under the tag. Download and sideload from `github.com/OneDeveloperCoding/latitude-tracker/releases`. Signed with the debug key (sufficient for personal/closed sideloading; not Play Store compatible).

## Git

Remote: `git@github-latitude:OneDeveloperCoding/latitude-tracker.git`
SSH key: `~/.ssh/id_ed25519_latitude` (mapped via `~/.ssh/config`)
Identity: OneDeveloperCoding / onedevelopercoding@gmail.com (local repo config)

### Branching

- `main` is always release-ready — only moves forward via feature/fix branch merges
- Branch naming: `feat/<short-description>` or `fix/<short-description>` (e.g. `feat/firebase-analytics`, `fix/nif-badge-crash`)
- Tag `main` when the accumulated changes are worth a release (see [Releases](#releases))

### Commit message convention

All commits follow [Conventional Commits](https://www.conventionalcommits.org):

```
<type>: <short description>
```

| Type | When to use |
|---|---|
| `feat` | new feature or user-visible behaviour |
| `fix` | bug fix |
| `perf` | performance improvement |
| `refactor` | code restructure with no behaviour change |
| `docs` | documentation or changelog only |
| `chore` | tooling, dependencies, config |
| `ci` | CI/CD workflow changes |

Examples: `feat: add heat map view`, `fix: nif badge crash on empty buyer`, `docs: update CHANGELOG for v1.1.0`

## Architecture notes

- Feature-based folder structure under `lib/features/`
- All Firestore data scoped to `users/{uid}/` — single-user, no sharing
- Photos stored at `users/{uid}/sales/{saleId}/photos/` in Firebase Storage
- See `CONTEXT.md` for domain language, data model, screen inventory, and deletion rules

### Key modules

| File | Purpose |
|------|---------|
| `features/sales/models/sale_filter.dart` | `SaleFilter` enum + `.test(sale)` predicate extension — single definition used by the sales list, dashboard stats, and any future callers |
| `features/dashboard/models/dashboard_stats.dart` | `DashboardStats.compute(sales, start, end)` — pure function, no Flutter dependency, straightforward to unit test |
| `features/buyers/models/buyer_stats.dart` | `BuyerStats.compute(sales)` — per-buyer metrics (paid total, unpaid balance, avg order, last purchase); used by buyers list, buyer detail, and new sale repeat-buyer hint |
| `features/heat_map/services/heat_map_service.dart` | `HeatMapService.buildPoints(sales)` — locality-prefix grouping + rate-limited Nominatim geocoding; `_MapView` is a pure rendering widget |
| `features/sales/services/photo_service.dart` | All Firebase Storage operations; swap storage backend here only |
| `features/sales/services/sale_urgency.dart` | `extension SaleUrgency on Sale` — `urgencyLevel()` / `urgencyReasons()` / `daysUntilScheduled()` — single authoritative urgency source used by sales list, shopping list, and sale filter |
| `features/sales/services/sale_grouper.dart` | `SaleGrouper.byWeek(sales)` — timeline grouping logic extracted from the sales list; pure function, testable in isolation |
| `core/store/sales_store.dart` + `buyers_store.dart` | Singleton shared streams — initialized once in `MainNav`, all screens subscribe via `ValueListenableBuilder<StoreState<T>>` instead of opening their own Firestore listeners |
| `core/store/store_state.dart` | `StoreState<T>` sealed class (`StoreLoading` / `StoreLoaded` / `StoreError`) — replaces null-as-loading convention |
| `core/services/postal_code_service.dart` | `PostalCodeService.lookup(postalCode)` — GeoAPI.pt client with 180-day `shared_preferences` cache; returns `PostalCodeResult(streets: List<String>, city)`; single match auto-fills, multiple matches show a picker sheet |
| `features/buyers/widgets/address_form_fields.dart` | `AddressFormFields` — reusable address form widget used by both buyer creation and address editing; handles postal code lookup, city auto-fill, and all structured address fields |

### Language

The app defaults to Portuguese (`pt`). The user can switch to English via **Settings → Language** (`SegmentedButton` PT / EN). The preference is persisted via `shared_preferences`. Changing language instantly rebuilds the entire widget tree — `MaterialApp.locale` is driven by `ValueListenableBuilder<Locale>` on `LocaleSettings.locale`. `Intl.defaultLocale` is also updated so `DateFormat` month names switch automatically.

All UI strings live in `lib/core/l10n/app_strings.dart` (`AppStrings.pt` / `AppStrings.en` const instances). Access via `context.s` extension. Demo data strings remain in English regardless of locale.

### Demo mode

Accessible from the login screen without credentials. Seeded with 7 hand-crafted active sales (covering all UI states) and 248 generated historical sales across 18 months, using a fixed `Random(42)` seed for deterministic output. A tutorial bottom sheet auto-displays on first entry and can be re-opened via the **?** button in the demo banner.

### Shared data stores

`SalesStore` and `BuyersStore` are singleton `ValueNotifier`s initialized once in `MainNav.initState()` and disposed in `MainNav.dispose()`. Every screen that needs sales or buyers data subscribes via `ValueListenableBuilder<StoreState<List<T>>>` instead of opening its own Firestore stream. This keeps exactly one active WebSocket connection per collection regardless of how many screens are mounted.

State is typed via the `StoreState<T>` sealed class — `StoreLoading`, `StoreLoaded(data)`, `StoreError(error)` — so loading and error states are distinct and exhaustive.

### Buyer address auto-fill

`BuyerAddress` stores structured fields: label, country, postal code, city, street, house number, fraction (optional), and delivery notes (optional).

For Portuguese addresses, entering a full `XXXX-XXX` postal code triggers a lookup via [GeoAPI.pt](https://geoapi.pt) which returns the street name and locality. Results are cached locally in `shared_preferences` for 180 days so repeated entries for the same postal code are instant and offline. City always overwrites from the API result; street only fills if the user hasn't typed one yet. For non-Portuguese addresses all fields are free text.

The `AddressFormFields` widget is shared between the quick-add during buyer creation and the standalone address edit screen — no duplication.

### App icon

Icons are generated via `flutter_launcher_icons` from `assets/icon/icon.png` (1024×1024 PNG). To regenerate after changing the source image:

```bash
dart run flutter_launcher_icons
```

### Sale card progress path

Each sale card in the list shows a three-node path: **Assembly → Payment → Shipment**. Nodes are icon + colour per state; connectors turn green as steps complete. Tap the **ℹ** button in the sales list AppBar to open a legend explaining all icons and colours. The path is implemented in `_SaleProgressPath` / `_PathNode` inside `sales_list_screen.dart` — no external widget file needed at this scale.

Urgency signals on each card:
- **Left accent bar** — red (overdue + blocker) or amber (this week + blocker); drawn via `BoxDecoration(border: Border(left: ...))` to avoid layout issues inside `ListView`
- **`receipt_long` badge** — purple = NIF unfiled after payment, green = filed; tap opens AT status sheet
- **Blocker badge** — specific icon per single blocker, generic ⚠️ for multiple; tap lists all reasons

### Sale fields of note

| Field | Type | Notes |
|-------|------|-------|
| `assemblyStatus` | `AssemblyStatus` enum | 4 values: `notStarted`, `waitingForMaterials`, `inProgress`, `ready` |
| `atSubmissionDone` | `bool` | Omitted from Firestore when `false`; existing documents deserialise correctly via `?? false` |
| `notes` | `String?` | Omitted from Firestore when null |
| `scheduledDate` | `DateTime?` | Used for timeline grouping and urgency thresholds |

### Tests

Unit tests live in `test/` mirroring the `lib/` feature structure. Run with:

```bash
flutter test --no-pub
```

Tests are also run automatically in CI on every tag push — the APK build is blocked if any test fails.

| File | Coverage |
|------|----------|
| `test/features/sales/sale_urgency_test.dart` | `SaleUrgency` — urgency level week boundaries, blocker reasons, days-until-scheduled |
| `test/features/sales/sale_filter_test.dart` | All 9 `SaleFilter` variants including date-sensitive overdue boundary |
| `test/features/sales/sale_model_test.dart` | `Sale.deriveAssemblyStatus` — component auto-ready logic |
| `test/features/buyers/buyer_stats_test.dart` | `BuyerStats.compute` — totals, average order value, last purchase |

### Screens added since initial build

| Screen | Entry point |
|--------|------------|
| `UnpaidBalancesScreen` | Dashboard Unpaid card |
| `NifPendingScreen` | Dashboard NIF required card |
| `ShoppingListScreen` | Dashboard Assembly not ready card |
