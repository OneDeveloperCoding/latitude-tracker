# Latitude Tracker

A private mobile app for a solo artisan seller in Portugal to track sales, payments, and shipments for unique handmade accessories (necklaces, earrings, tote bags, hats). Sold primarily through Instagram DMs and in-person at events. Used on two devices (phone + tablet) under a single account.

## Language

**Sale**:
A transaction where one or more Items are sold to a Buyer at an agreed price. Records payment, shipment, NIF requirement, components checklist, and photos.
_Avoid_: Order, purchase, transaction

**Buyer**:
A person who purchases Items, identified by name and optionally an Instagram handle, phone number, and NIF. A Buyer persists across multiple Sales.
_Avoid_: Customer, client, user

**BuyerAddress**:
A named shipping address belonging to a Buyer (e.g. "Home", "Work"). A Buyer may have multiple BuyerAddresses; one may be marked as default.
_Avoid_: Delivery address, shipping address (as a standalone concept)

**NIF**:
Portuguese tax identification number (Número de Identificação Fiscal). Stored optionally on a Buyer profile. Each Sale independently records whether the buyer requested a NIF receipt for that transaction — even if their profile has a NIF saved, they may opt out per sale.
_Avoid_: Tax number, fiscal number

**Item**:
A unique, one-of-a-kind physical product (e.g. necklace, earring, tote bag, hat). Not tracked as inventory. Each Item in a Sale has an AssemblyStatus and a ComponentChecklist.
_Avoid_: Product, SKU, stock

**AssemblyStatus**:
The production state of an Item within a Sale: `not_started`, `in_progress`, or `ready`. Determines whether the Item can be shipped.
_Avoid_: Production status, build status

**ComponentChecklist**:
A per-Sale list of materials or pieces needed to make the Item (e.g. "silver chain", "blue bead"). Each entry is marked as `have` or `need_to_buy`. Acts as a shopping list for that specific Sale.
_Avoid_: Bill of materials, inventory, stock list

**Payment**:
Money received (or owed) for a Sale. Has a status (paid / unpaid) and a method (MB Way, cash, SumUp card, bank transfer).
_Avoid_: Invoice, charge

**Shipment**:
The physical delivery of Items from a Sale to a Buyer. Has a status (pending / shipped / delivered), optionally a CTT tracking code, and a postal code used for geographic analytics. References a BuyerAddress if shipped.
_Avoid_: Delivery, fulfillment, dispatch

**Dashboard**:
A summary screen showing revenue and action counts for a selected period (yearly / monthly / weekly). Displays paid and pending revenue, plus counts for unpaid Sales, pending Shipments, assembly-not-ready Items, NIF-required Sales, and overdue deliveries. Tapping a count navigates to the filtered Sales list.
_Avoid_: Report, analytics, overview

**SalesHeatMap**:
A geographic view showing the distribution of online Sales by postal code, visualised as a heat map over a map of Portugal.
_Avoid_: Geographic report, map view

**Archive**:
A read-only export of Sales, Buyers, and BuyerAddresses for a given year, shared via the OS share sheet (Google Drive, email, etc.). Can be re-imported into the app for historical lookup only. The JSON includes `photoUrls` for each Sale — since photos are kept in Firebase Storage after a year purge, they remain viewable in the import screen via those URLs.
_Avoid_: Backup, dump

## Relationships

- A **Sale** belongs to exactly one **Buyer** (stores `buyerId` + `buyerName` as a snapshot)
- A **Sale** has one **Payment** (which may be unpaid)
- A **Sale** records whether a NIF receipt was requested (independent of the Buyer's saved NIF)
- A **Sale** has one **Shipment** OR is marked as in-person pickup (no Shipment needed)
- A **Sale** has one **ComponentChecklist** and one **AssemblyStatus** per Item
- A **Shipment** references one **BuyerAddress** and records a postal code
- A **Sale** may have zero or more photos (compressed to max 1200px wide, JPEG quality 85, ~200–300KB each)
- A **Buyer** may have multiple **Sales** over time
- A **Buyer** may have multiple **BuyerAddresses**; one is marked as default
- A **Buyer** may optionally have a saved **NIF**
- An **Archive** is read-only — Sales cannot be edited after archiving

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

**Removing a photo from a Sale:**
- If removed during an active edit session and it was a new upload (not yet saved): deleted from Storage immediately
- If removed during an active edit session and it was a pre-existing photo: marked for deletion, actually deleted from Storage only when the Sale is saved
- If the edit is cancelled instead of saved: only photos uploaded in that session are deleted; pre-existing photos are restored

## Photo lifecycle

Photos are stored in Firebase Storage under `users/{uid}/sales/{saleId}/photos/{uuid}.jpg`.

**Upload:** triggered from the new/edit sale screen or the sale detail photo grid. Each image is compressed by `image_picker` before upload (maxWidth: 1200px, JPEG quality: 85), producing files of roughly 200–300KB. Multiple photos per Sale are supported.

**Orphan prevention:** three layers ensure no photo is ever left in Storage without a corresponding Sale:
1. Cancel new sale → all photos uploaded in that session are deleted
2. Cancel sale edit → only photos added in that edit session are deleted; originals are untouched
3. Delete sale → `PhotoService.deleteAllPhotos(saleId)` lists and deletes all files under that Sale's Storage folder before the Firestore document is removed

**Year purge exception:** when a year is purged from Settings, the Firestore documents are deleted but photos are deliberately kept. The archive JSON export includes the original `photoUrls`, so photos remain visible when the archive is re-imported into the app.

**Cost:** at 500–1000 photos/year (200–300KB each), Storage grows by ~125–300MB/year. On Firebase Blaze pricing (~€0.026/GB/month), this costs under €0.05/month even after several years of use. No external storage solution is needed at this scale.

**Expandability:** all Storage operations are isolated in `lib/features/sales/services/photo_service.dart`. Swapping the storage backend (e.g. to Google Drive) requires changes only to that file.

## Screens

1. **Login** — email + password, stays logged in permanently
2. **Dashboard** — period selector (yearly / monthly / weekly); paid + pending revenue; action cards for unpaid, pending shipment, assembly not ready, NIF required, overdue; tapping a card navigates to filtered Sales list
3. **Sales list** — all Sales, filter chips (all, unpaid, NIF required, scheduled, pending shipment, shipped, pickup, assembly not ready, overdue); timeline view groups by scheduled/created date with an Overdue section for past-due undelivered Sales
4. **New/edit sale** — pick Buyer (with quick inline Buyer + address creation), describe Item, add multiple photos, set AssemblyStatus, add ComponentChecklist, set price, Payment method, NIF required flag, shipping or in-person pickup, optional scheduled delivery date; orphan photo cleanup on cancel
5. **Sale detail** — live view/edit via stream; photo grid at top; assembly dropdown; component checklist; scheduled date (set / change / clear); payment card with paid toggle; delivery card with status dropdown, full address display, CTT tracking code (tappable → opens ctt.pt)
6. **Buyers list** — all Buyers, searchable
7. **Buyer detail** — view/edit Buyer info (name, Instagram, phone, NIF); BuyerAddresses list with default badge, add/edit/delete; each address shows full address with edit/delete popup
8. **Sales heat map** — placeholder; planned: postal code heat map of online Sales over Portugal
9. **Settings** — account info + sign out; export year (JSON via share sheet); import archive (browse read-only); delete year (double-confirmed, deletes sales + photos); app version

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
