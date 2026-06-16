# Latitude Tracker

A private mobile app for a solo artisan seller in Portugal to track sales, payments, and shipments for unique handmade accessories (necklaces, earrings, tote bags, hats). Sold primarily through Instagram DMs and in-person at events. Used on two devices (phone + tablet) under a single account.

## Language

**Sale**:
A transaction where one or more SaleItems are sold to a Buyer. The total price is derived as the sum of its SaleItems' prices. Records payment, shipment, NIF requirement, AT submission status, and optional free-text notes (e.g. gift wrap requests, colour preferences). Assembly status at the sale level is derived as the worst-case status across all SaleItems.
_Avoid_: Order, purchase, transaction

**Buyer**:
A person who purchases Items, identified by name and optionally an Instagram handle, phone number, and NIF. A Buyer may have free-text tags (e.g. "instagram", "in-person", "vip") and a freeform notes field for seller observations. A Buyer persists across multiple Sales.
_Avoid_: Customer, client, user

**BuyerAddress**:
A named shipping address belonging to a Buyer (e.g. "Home", "Work"). Fields: label, country (default: Portugal), postal code, city, street name, house number, and optional fraction (e.g. "2º Dto", "R/C"). For Portuguese addresses, entering the postal code auto-fills city and street via GeoAPI.pt (180-day local device cache). A Buyer may have multiple BuyerAddresses; one may be marked as default.
_Avoid_: Delivery address, shipping address (as a standalone concept)

**NIF**:
Portuguese tax identification number (Número de Identificação Fiscal). Stored optionally on a Buyer profile. Each Sale independently records whether the buyer requested a NIF receipt for that transaction — even if their profile has a NIF saved, they may opt out per sale.
_Avoid_: Tax number, fiscal number

**SaleItem**:
A unique, one-of-a-kind physical product within a Sale (e.g. necklace, earring, tote bag, hat). Has its own description, ItemCategory, price, AssemblyStatus, ComponentChecklist, and photos. Not tracked as inventory — it exists only as part of a Sale. Code name: `SaleItem`.
_Avoid_: Product, SKU, stock, Item (too generic in code)

**ItemCategory**:
A free-text string on a SaleItem (and Repair) that classifies its product type. Seeded with defaults (e.g. Colares, Brincos, Chapéus); the seller can add custom categories which are auto-discovered from existing SaleItems and Repairs and offered in the picker. Not an enum — new categories are added by typing them. Used for filtering in the Sales list and for per-category revenue analytics (e.g. "€100 in Colares this month"). A category can be **hidden** via Settings → Categories: it is removed from the picker but not from existing records — history and analytics are preserved. Rename (batch-updates all SaleItems and Repairs), hide/unhide, and delete (only when use count = 0) are managed from `CategoryMaintenanceScreen`. The hidden list is persisted at `users/{uid}/settings/catalogue` as `hiddenCategories: []`.
_Avoid_: Product type, product category (implies a separate catalogue entity)

**AssemblyStatus**:
The production state of a SaleItem: `not_started`, `waiting_for_materials`, `in_progress`, or `ready`. `waiting_for_materials` means the seller knows components must be purchased before work can start — typically used for event orders taken before materials are sourced. Determines whether the SaleItem can be shipped. The Sale-level assembly status is derived as the worst-case status across all its SaleItems (a Sale is only `ready` when every SaleItem is `ready`).
_Avoid_: Production status, build status

**ComponentChecklist**:
A per-SaleItem list of materials or pieces needed to make that item (e.g. "silver chain", "blue bead"). Each entry is marked as `have` or `need_to_buy`. Acts as a shopping list for that specific SaleItem.

Each entry is a **ComponentItem**: a named material with a stable `id` (UUID), a `quantity: int` (how many are needed, default 1), an `isAvailable` toggle, optional `notes` (e.g. "get the 45cm length, not 50cm"), and zero or more `photoUrls` (visual reference for shopping). The `isAvailable` toggle is all-or-nothing — toggling means "I have all N" / "I still need all N"; partial acquisition is not tracked. The `isAvailable` toggle and a `−/+` quantity stepper are both inline on the checklist row. Photos and notes are accessed via a component detail sheet (opened by a separate photo icon on the row), which shows in edit mode (from `SaleItemScreen` / Sale detail) or read-only mode (from `ShoppingList`). The ShoppingList shows `× N` next to the component name only when `quantity > 1`.
_Avoid_: Bill of materials, inventory, stock list

**Payment**:
Money received (or owed) for a Sale. Has a status (paid / unpaid) and a method (MB Way, cash, SumUp card, bank transfer).
_Avoid_: Invoice, charge

**Shipment**:
The physical delivery of Items from a Sale to a Buyer. Has a `DeliveryType` (`shipping`, `pickup`, or `handDelivery`), a status, an optional CTT tracking code, and a postal code used for geographic analytics. References a BuyerAddress for `shipping` and `handDelivery`. Status flow differs by type: `shipping` goes `pending → shipped → delivered`; `pickup` and `handDelivery` go `pending → delivered` (the `shipped` state is never written for those). Hand delivery is seller-delivered within the same city — address and postal code are required (used in the SalesHeatMap), tracking code is absent.
_Avoid_: Delivery, fulfillment, dispatch

**Repair**:
A repair job for a physical item brought in by a contact. Distinct from a Sale — Repairs are tracked separately and their revenue is never mixed into Sale analytics. A Repair may optionally reference the original Sale the item came from. Contact is required: either a linked Buyer or a free-text name (which can be promoted to a full Buyer later). Fields: item description, ItemCategory, problem description, work done (free text), materials cost (optional), photos, RepairStatus, Payment, and ReturnDelivery.
_Portuguese_: Reparação
_Avoid_: Order, job ticket, work order

**RepairStatus**:
The current state of a Repair job: `received` (item is with the seller), `waiting_for_materials` (parts must be sourced before work can start), `in_progress` (work is underway), `done` (repair complete, item still with seller), `returned` (item back with the customer). Selection is free — no enforced linear progression, except that the quick-action "Mark as Delivered" button on the detail screen automatically advances RepairStatus to `returned` at the same time it sets ReturnDelivery status to `delivered`. A Repair is considered "active" (shown in the default list view) unless RepairStatus is `returned` AND ReturnDelivery status is `delivered`.
_Avoid_: Repair state, job status

**ReturnDelivery**:
The logistics of returning a repaired item to the customer. Has a `DeliveryType` (`shipping`, `pickup`, or `handDelivery`), a status (pending / shipped / delivered), an optional CTT tracking code, and an optional postal code (for `shipping` returns only). `handDelivery` requires an address but no tracking code, same as on a Sale Shipment. Separate from RepairStatus — a Repair can be `done` while ReturnDelivery is still `pending` (item ready but not yet dispatched). Mirrors the Shipment pattern on a Sale.
_Avoid_: Return shipment, return tracking

**Dashboard**:
A summary screen showing revenue and action counts for a selected period (yearly / monthly / weekly). Displays paid and pending revenue, plus counts for unpaid Sales, pending Shipments, assembly-not-ready Items, NIF-required Sales, and overdue deliveries. Tapping a count navigates to the filtered Sales list.
_Avoid_: Report, analytics, overview

**AnalyticsScreen**:
An analytics screen reached from the insights icon button in the Dashboard revenue card. Shows per-category revenue as a stacked bar chart across 6 periods, with a payment method breakdown and top-categories section. Supports a revenue/count metric toggle and multi-select category filtering. Period navigation adapts to the selected period type (weekly / monthly / yearly). Formerly split across a separate InsightsCard widget and a TrendsScreen — now a single unified screen.
_Avoid_: Analytics dashboard, reports screen, TrendsScreen (old name)

**SalesHeatMap**:
A geographic view showing the distribution of Sales with a postal code (shipping and hand delivery) by postal code, visualised as a heat map over a map of Portugal. Sales are grouped by 4-digit locality prefix (e.g. 3000-550 and 3000-313 both map to "3000" → one marker for Coimbra). Only Portuguese postal codes are plotted; foreign addresses are excluded. An AppBar toggle (`directions_walk` icon, `isSelected` style) lets the seller exclude hand deliveries from the map when local clustering obscures the broader geographic picture; default is included.
_Avoid_: Geographic report, map view

**ShoppingList**:
An aggregated view of all materials still needed to complete open Sales. Shows every ComponentItem with `isAvailable: false` grouped by Sale, filtered to Sales that are not yet assembled and not yet delivered. Component notes are shown inline below the name when present. A photo count badge on each row opens a read-only photo viewer for visual reference; no upload or edit from this screen.
_Avoid_: Inventory, stock, bill of materials (those imply tracked quantities)

**UnpaidBalances**:
A buyer-centric view of all outstanding payments. Groups unpaid Sales by Buyer, sorted by total amount owed descending. The entry point when deciding who to follow up with.
_Avoid_: Debt, accounts receivable

**NifPending**:
A list of Sales that require a NIF receipt, shown alongside the Buyer's saved NIF number and AT submission status. Pending submissions are shown first; filed ones remain visible as a historical record.
_Avoid_: Tax report, invoice list

**ATSubmission**:
The act of filing a NIF receipt with the Autoridade Tributária for a given Sale. A Sale either has a pending AT submission (not yet filed) or a completed one (filed). This is a one-way toggle tracked per Sale — once filed it can be undone if needed. Unrelated to whether the Buyer's NIF is saved on their profile.
_Avoid_: Invoice, filing, tax return

**Archive**:
A read-only export of Sales, Buyers, and BuyerAddresses for a given year, shared via the OS share sheet (Google Drive, email, etc.). Can be re-imported into the app for historical lookup only. The JSON includes `photoUrls` for each Sale — since photos are kept in Firebase Storage after a year purge, they remain viewable in the import screen via those URLs.
_Avoid_: Backup, dump

**Archive JSON schema (version 1.3)**:
```json
{
  "version": "1.3",
  "exportedAt": "<ISO-8601 string>",
  "year": 2026,
  "sales": [
    {
      "id": "<uuid>",
      "buyerId": "...", "buyerName": "...",
      "items": [ { "id": "...", "description": "...", "category": "...", "price": 0.0,
                   "assemblyStatus": "notStarted|...",
                   "components": [
                     { "id": "<uuid>", "name": "silver chain", "quantity": 1, "isAvailable": true,
                       "photoUrls": ["https://..."], "notes": "45cm length" }
                   ],
                   "photoUrls": [...] } ],
      "payment": { "status": "paid|unpaid", "method": "mbWay|cash|sumup|bankTransfer" },
      "shipment": { "type": "shipping|pickup|handDelivery", "status": "pending|shipped|delivered",
                    "trackingCode": null, "addressId": null, "postalCode": null },
      "requiresNif": false, "atSubmissionDone": false,
      "createdAt": "<ISO-8601 string>",
      "scheduledDate": "<ISO-8601 string or null>",
      "notes": null
    }
  ],
  "buyers": [
    {
      "id": "<uuid>",
      "name": "...", "instagramHandle": null, "phone": null, "nif": null,
      "tags": [], "notes": null,
      "createdAt": "<ISO-8601 string>",
      "addresses": [
        { "id": "<uuid>", "label": "...", "street": "...", "houseNumber": "...",
          "fraction": null, "notes": null, "city": "...", "postalCode": "...",
          "country": "Portugal", "isDefault": false }
      ]
    }
  ]
}
```
Date fields (`createdAt`, `scheduledDate`) are exported as ISO-8601 strings and converted back to Firestore Timestamps on import. Version `"1.1"` added a `repairs` array alongside `sales`. Version `"1.2"` adds `handDelivery` as a valid `shipment.type` value. Version `"1.3"` expands the `components` array schema to include `id`, `photoUrls`, and `notes` per ComponentItem. On import, all recognised versions (`"1.0"`, `"1.1"`, `"1.2"`, `"1.3"`, `"1.4"`) are accepted; an unknown `DeliveryType` string falls back to `shipping` rather than throwing. `ArchiveService` rejects archives whose `version` field is not a recognised version with a `FormatException`. Version `"1.4"` adds `quantity: int` to each ComponentItem entry; archives from earlier versions default `quantity` to `1` on import.

## Relationships

- A **Sale** belongs to exactly one **Buyer** (stores `buyerId` + `buyerName` as a snapshot)
- A **Sale** has one or more **SaleItems** (minimum 1); total price is the sum of SaleItem prices
- A **Sale** has one **Payment** (which may be unpaid); payment covers the whole Sale
- A **Sale** records whether a NIF receipt was requested (independent of the Buyer's saved NIF)
- A **Sale** with `requiresNif` tracks whether its **ATSubmission** is pending or completed
- A **Sale** has one **Shipment** OR is marked as in-person pickup (no Shipment needed)
- A **Shipment** references one **BuyerAddress** and records a postal code
- A **Sale** may have optional free-text notes (special instructions, gift requests, colour choices)
- A **SaleItem** has one **AssemblyStatus** and one **ComponentChecklist**
- A **SaleItem** may have zero or more photos (compressed to max 1200px wide, JPEG quality 85, ~200–300KB each)
- A **Buyer** may have multiple **Sales** over time
- A **Buyer** may have multiple **BuyerAddresses**; one is marked as default
- A **Buyer** may optionally have a saved **NIF**
- An **Archive** is read-only — Sales cannot be edited after archiving
- A **Repair** has one **RepairStatus** and one **ReturnDelivery**
- A **Repair** has one **Payment** (same structure as Sale payment — amount, paid/unpaid, method)
- A **Repair** contact is either a linked **Buyer** (stores `buyerId` + `buyerName`) or a free-text name — one is required
- A **Repair** may optionally reference one **Sale** (the original Sale the item came from)
- A **Repair** may have zero or more photos (same compression and storage pattern as SaleItem photos)
- A **Sale** may have zero or more linked **Repairs** (visible as a section on the Sale detail screen)

## Data deletion rules

These rules define exactly what is removed when each entity is deleted, and what is intentionally preserved.

**Deleting a single Sale:**
- Firestore document removed
- All photos for that Sale deleted from Firebase Storage immediately (before the Firestore delete, to avoid orphans)
- The Buyer profile is unaffected
- Any BuyerAddress referenced by the Shipment is unaffected

**Purging a year (Settings → Delete archived year):**
- All Sale Firestore documents for that year are batch-deleted
- Photos are **not** deleted — they remain in Firebase Storage at their original paths (`users/{uid}/sales/{saleId}/photos/`)
- This is intentional: the archive JSON export contains `photoUrls` for each Sale, so photos stay viewable in the import screen after the year is purged
- Buyer profiles and BuyerAddresses are unaffected

**Deleting a Buyer:**
- Buyer Firestore document removed
- All BuyerAddresses for that Buyer removed (batch delete)
- Sales are **not** deleted — they retain `buyerName` as a plain string and remain fully intact; they simply no longer link to a live Buyer profile
- Photos attached to those Sales are unaffected

**Deleting a BuyerAddress:**
- BuyerAddress Firestore document removed
- Any Sale whose Shipment references that address is unaffected (the address data was copied into the Shipment at the time of sale)

**Deleting a single Repair:**
- Firestore document removed
- All photos for that Repair deleted from Firebase Storage immediately (before the Firestore delete, to avoid orphans)
- The linked Sale (if any) is unaffected
- The linked Buyer (if any) is unaffected

**Purging a year (includes Repairs):**
- All Repair Firestore documents for that year are batch-deleted alongside Sales
- Repair photos are **not** deleted — same intentional exception as Sale photos; the Archive JSON includes `photoUrls`

**Removing a photo from a Sale:**
- If removed during an active edit session and it was a new upload (not yet saved): deleted from Storage immediately
- If removed during an active edit session and it was a pre-existing photo: marked for deletion, actually deleted from Storage only when the Sale is saved
- If the edit is cancelled instead of saved: only photos uploaded in that session are deleted; pre-existing photos are restored

## Photo lifecycle

Photos are stored in Firebase Storage under `users/{uid}/sales/{saleId}/items/{itemId}/photos/{uuid}.jpg` — scoped per SaleItem.

**Upload:** triggered from the SaleItemScreen (during new/edit sale) or from the item detail view in the Sale detail screen. Each image is compressed by `image_picker` before upload (maxWidth: 1200px, JPEG quality: 85), producing files of roughly 200–300KB. Multiple photos per SaleItem are supported.

**Orphan prevention:** three layers ensure no photo is ever left in Storage without a corresponding Sale:
1. Cancel new sale → all photos uploaded in that session are deleted
2. Cancel sale edit → only photos added in that edit session are deleted; originals are untouched
3. Delete sale → `PhotoService.deleteAllPhotos(saleId)` lists and deletes all files under that Sale's Storage folder (including all item subfolders) before the Firestore document is removed

**Year purge exception:** when a year is purged from Settings, the Firestore documents are deleted but photos are deliberately kept. The archive JSON export includes the original `photoUrls`, so photos remain visible when the archive is re-imported into the app.

**Cost:** at 500–1000 photos/year (200–300KB each), Storage grows by ~125–300MB/year. On Firebase Blaze pricing (~€0.026/GB/month), this costs under €0.05/month even after several years of use. No external storage solution is needed at this scale.

**Expandability:** all Storage operations are isolated in `lib/features/sales/services/photo_service.dart`. Swapping the storage backend (e.g. to Google Drive) requires changes only to that file.

**Component photos:** stored at `users/{uid}/sales/{saleId}/items/{itemId}/components/{componentId}/photos/{uuid}.jpg`. Same compression settings. Orphan prevention: cancel edit → session uploads deleted (folded into the SaleItem's `_uploadedInSession` list); delete component → session uploads deleted immediately, pre-existing URLs queued to `_pendingDeletions`; delete SaleItem or delete Sale → covered by `PhotoService.deleteAllPhotos(saleId)` which recursively deletes the entire sale folder. Year purge exception applies: photos kept, Archive JSON includes `photoUrls` per component. From the Sale detail screen, component photo changes save immediately (same pattern as SaleItem photos in the detail view). From `ShoppingList`, photos are view-only — no upload or delete.

**Repair photos:** stored at `users/{uid}/repairs/{repairId}/photos/{uuid}.jpg`. Same compression settings (maxWidth: 1200px, JPEG quality: 85). Same orphan-prevention lifecycle as Sale photos: cancel new repair → delete session uploads; cancel edit → delete only session uploads; delete repair → delete all photos before Firestore doc. Year purge exception applies: photos kept, Archive JSON includes `photoUrls`.

## Screens

1. **Login** — email + password, stays logged in permanently; "Try Demo" button enters Demo mode without credentials

1a. **Demo mode** — read-only sandbox with 255 pre-seeded sales across 18 months (7 hand-crafted active + 248 generated historical, fixed `Random(42)` seed) and ~5–8 hand-crafted Repairs (mix of RepairStatuses, some linked to demo Sales, some with free-text contacts). A tutorial bottom sheet auto-displays on first entry; re-accessible via **?** in the demo banner. Write operations (add/edit/delete) are blocked. Demo data strings are in English regardless of app language setting.

2. **Dashboard** — scrollable 6-month chip row for period selection (monthly granularity only); paid revenue card with an insights icon button that navigates to the AnalyticsScreen. Seven action rows grouped into three labelled sections:
   - **Money**: Unpaid (count + total €), Overdue, NIF required
   - **Production**: Assembly not ready, Pending shipment, In transit
   - **Planning**: Upcoming scheduled
   Each row taps to its dedicated view (UnpaidBalances, filtered Sales list, ShoppingList, NifPending). Inactive rows (count = 0) are shown dimmed and non-tappable.

2a. **AnalyticsScreen** — period-navigable analytics screen with a **Sales / Repairs tab bar**. Accessed from the Dashboard insights icon button only (lands on Sales tab); launched with the Dashboard's current period pre-selected. **Sales tab:** stacked bar chart of per-category revenue across 6 periods; bars dim until tapped to reveal period totals and per-category value rows; multi-select category chips act as legend and filter; metric toggle (revenue / count); payment method breakdown section; top categories section. **Repairs tab:** total repair revenue by period, count of Repairs by RepairStatus, most repaired ItemCategory. Period navigation is adaptive: weekly shows −1/−4/−52 week comparisons; monthly shows −1/−3/−6/−12; yearly shows −1/−3/−5.

3. **Sales / Repairs area** — the Sales bottom-nav tab contains two inner tabs: **Sales** (existing list) and **Repairs** (new list). The AppBar and FAB adapt to the active inner tab.

3. **Sales list** — default view shows only **active Sales** (not yet delivered); timeline grouped Overdue → This week → Next week → Later → past months. Tune icon opens a filter/sort sheet with grouped filters (Money / Logistics / Compliance), year chips (one per year that has Sales, dynamically generated), date range picker (mutually exclusive with year chips), inline buyer search (single-select). Sort is a separate AppBar popup with its own badge. Selecting a year chip shows **all** Sales in that calendar year including delivered ones, overriding the active-only default; grouping switches to creation month. Selecting a date range does not override the default (still hides delivered). Map icon in AppBar navigates to the standalone SalesHeatMap screen. Each Sale shown as a card: buyer name + derived total price top row; SaleItem descriptions one per line (up to 3; "and X more" tappable to a bottom sheet if more) + attention badges right; one ItemCategory chip per unique category across all SaleItems (wrapping); creation date left + due date right; age indicator (hourglass icon — amber after 14 days open, red after 30 days, hidden for fresh or delivered sales); progress path spanning full card width at the bottom (tap → legend). Left accent bar: red = overdue with blockers, amber = this week with blockers. Attention badges (tap to open detail sheet): `receipt_long` purple = NIF unfiled (also shown in orange when no NIF on file), green = NIF filed; `price_check` = assembly ready but unpaid; specific blocker icon = single urgency reason, generic ⚠️ = multiple.

4. **New/edit sale** — Buyer section (inline Buyer + address creation; repeat-buyer hint shows "X previous sales · last: MMM YYYY"); SaleItems list (each item edited on a dedicated SaleItemScreen with description, ItemCategory, price, AssemblyStatus, ComponentChecklist, photos); Payment section (method, paid/unpaid, NIF required flag); Delivery section (type, address, CTT tracking code, scheduled date); Notes section. Sale total is shown as derived sum of SaleItem prices. Orphan photo cleanup on cancel.

4a. **SaleItemScreen** — sub-screen pushed from the new/edit sale form for adding or editing a single SaleItem: description, ItemCategory, price, AssemblyStatus (including `waiting_for_materials`), ComponentChecklist, and photos.

5. **Sale detail** — live stream; SaleItems list (description, category, price per item; tap item to see its assembly status, component checklist, and photos); derived total price; payment toggle; unified NIF/AT compliance row that progresses through four states — (1) no NIF on file (with inline "Add NIF" dialog that saves to Buyer without leaving the screen), (2) NIF receipt required but AT not yet filed, (3) AT pending, (4) AT filed — shown when `requiresNif`; delivery card with status, address, CTT tracking code; **Repairs section** (only shown when at least one Repair is linked to this Sale — lists each Repair with description, RepairStatus, and date; each row taps to Repair detail); Notes card (inline editable); buyer name taps to Buyer detail

5a. **Repairs list** — inner tab within the Sales/Repairs area. Default view shows only **active Repairs** (RepairStatus ≠ `returned`, or ReturnDelivery status ≠ `delivered`). No AppBar — a filter row sits at the top of the body: a search chip (expands to a text field, searches contact name and item description) and a tune icon with a badge counting active constraints. Tune sheet contains: date sort (newest/oldest toggle) and RepairStatus filter chips; selecting any chip overrides the active-only default and shows only that status. FAB creates a new Repair. Each Repair shown as a card: contact name (Buyer link or free-text), item description, ItemCategory chip, RepairStatus badge, date received, unpaid indicator; when status is `done` or `returned` a ReturnDelivery indicator row is shown below a divider (icon + status label, coloured grey/blue/green by shipment progress).

5b. **New/edit Repair** — Contact section (Buyer picker or free-text name entry); item description; ItemCategory picker (same seeded defaults as SaleItem); problem description; Work done field; materials cost; RepairStatus picker; Payment section (same fields as Sale payment); ReturnDelivery section (type: shipping/pickup; status; CTT tracking code; postal code for shipping); photos; optional linked Sale picker. Orphan photo cleanup on cancel.

5c. **Repair detail** — live stream; contact row (taps to Buyer detail if linked, "Promote to Buyer" action if free-text); linked Sale row (if set, taps to Sale detail); item description, category, problem description; Work done field (inline editable); photos; materials cost; RepairStatus picker; Payment card; ReturnDelivery card. When RepairStatus is `done` or `returned` and ReturnDelivery is not yet `delivered`, the Return card shows a quick-action button: "Mark as Sent" (shipping, pending→shipped) or "Mark as Delivered" (all other cases). Pressing "Mark as Delivered" also auto-advances RepairStatus to `returned`.

6. **Buyers list** — all Buyers, searchable; three sort modes (alphabetical, grouped by last purchase, ranking); ranking metric chips (total spent, frequency, average order, unpaid balance)

7. **Buyer detail** — view/edit Buyer info; purchase history with year chips (all-time or a specific year) that drill down to month filter chips; summary row (total sales, paid, unpaid balance, avg order, last purchase); BuyerAddresses list

8. **Unpaid balances** — unpaid Sales grouped by Buyer, sorted by total owed; grand total header; collapsible buyer cards (name → buyer profile, sales → sale detail)

9. **NIF receipts pending** — all Sales with `requiresNif: true`; pending AT submissions first, filed ones after (history); header shows "X pending · Y filed"; each row shows buyer name, item, price, date, Buyer's saved NIF (red "No NIF on file" if absent), and a checkmark toggle to mark AT submission done/undone; filed rows shown at reduced opacity; taps to Sale detail

10. **Shopping list** — open Sales (assembly not ready + not delivered) that have unacquired components; grouped by Sale with buyer name, item, assembly badge, and each needed component

11. **Sales heat map** — standalone screen pushed from the Sales list AppBar (map icon). Independent year scope: all-time by default with a year chip bar in the AppBar, decoupled from the Sales list filters. Groups shipped Sales by 4-digit postal code locality prefix; geocodes via Nominatim with a layered cache (in-memory L1 + 180-day SharedPreferences L2); markers sized by sale count; tap → snackbar with locality name and count. Tile caching via BuiltInMapCachingProvider (50 MB cap). Background warm-up runs on every SalesStore data load.

12. **Settings** — sign out; export year to JSON (share sheet); import archive (read-only preview → Import button writes to Firestore, skipping existing records); delete year (optional photo deletion toggle); language toggle (PT / EN, persisted); app version

## Example dialogue

> **Dev:** "When she creates a Sale for a returning Buyer, does the address auto-fill?"
> **Domain expert:** "Yes — it should pre-fill with the Buyer's default BuyerAddress, but she should be able to pick a different one or add a new one on the spot."

> **Dev:** "When she records a Sale, does the Shipment get created at the same time?"
> **Domain expert:** "Yes — she marks it as shipping or in-person pickup at the point of sale. If shipping, she fills in the CTT tracking code later when she drops it off at CTT."

> **Dev:** "If a Buyer has a NIF saved, does it automatically apply to all their Sales?"
> **Domain expert:** "No — each Sale has its own NIF flag. The Buyer's NIF is just saved for convenience so she doesn't have to retype it, but the buyer decides per sale whether they want a NIF receipt."

> **Dev:** "Can archived Sales be edited after import?"
> **Domain expert:** "No — Archives are historical records. Read-only on re-import."

## Flagged ambiguities

- "order" was used informally — resolved to **Sale** to avoid confusion with e-commerce order management concepts.
- "address" initially assumed one per Buyer — resolved to **BuyerAddress** supporting multiple per Buyer with a default.
- "NIF on sale" clarified: the Buyer profile stores NIF for convenience, but each Sale independently records whether a NIF receipt was requested for that transaction.
- "components tracking" clarified: resolved to a simple **ComponentChecklist** per Sale, not a full inventory system.
- "returned" status for Repairs clarified: RepairStatus `returned` alone does not mark a Repair as inactive — it is only removed from the default active list view when *both* RepairStatus is `returned` AND ReturnDelivery status is `delivered`. This preserves visibility during the return-shipping window.
- Repair analytics placement clarified: Repair analytics live in the existing AnalyticsScreen (new Repairs tab), not a separate screen. This keeps analytics access unified under the Dashboard entry point.
- ComponentItem interaction model clarified: the `isAvailable` toggle and `−/+` quantity stepper are both inline on the checklist row. A separate photo icon button opens a component detail sheet (edit mode from `SaleItemScreen`/Sale detail; read-only from `ShoppingList`). Toggle is all-or-nothing regardless of quantity — "I have all N" / "I still need all N"; partial acquisition is not tracked.
- `AssemblyStatus` is fully manual — toggling ComponentItem availability has no effect on AssemblyStatus. The ComponentChecklist is the materials signal; AssemblyStatus is the assembly signal. Cross-SaleItem component aggregation (summing quantities of same-named components across SaleItems) is deferred to a future issue.
- Component photo deletion timing clarified: photos are deleted when the component is **removed**, not when toggled. Session uploads and pre-existing URLs are folded into the SaleItem's existing `_uploadedInSession` / `_pendingDeletions` lists — no separate tracking needed.
