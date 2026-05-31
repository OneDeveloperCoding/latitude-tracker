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
A summary screen showing total revenue for the current month, number of unpaid Sales, and number of pending Shipments.
_Avoid_: Report, analytics, overview

**SalesHeatMap**:
A geographic view showing the distribution of online Sales by postal code, visualised as a heat map over a map of Portugal.
_Avoid_: Geographic report, map view

**Archive**:
A read-only export of Sales data and associated photos for a given period, saved to the seller's Google Drive. Can be re-imported into the app for historical lookup only.
_Avoid_: Backup, dump

## Relationships

- A **Sale** belongs to exactly one **Buyer**
- A **Sale** has one **Payment** (which may be unpaid)
- A **Sale** records whether a NIF receipt was requested (independent of the Buyer's saved NIF)
- A **Sale** has one **Shipment** OR is marked as in-person pickup (no Shipment needed)
- A **Sale** has one **ComponentChecklist** and one **AssemblyStatus** per Item
- A **Shipment** references one **BuyerAddress** and records a postal code
- A **Sale** may have one or more photos attached (compressed to max 1200px / ~500KB before upload)
- A **Buyer** may have multiple **Sales** over time
- A **Buyer** may have multiple **BuyerAddresses**; one is marked as default
- A **Buyer** may optionally have a saved **NIF**
- An **Archive** is read-only — Sales and photos cannot be edited after archiving

## Screens

1. **Login** — email + password, stays logged in permanently
2. **Dashboard** — monthly revenue, unpaid Sales count, pending Shipments count
3. **Sales list** — all Sales, filterable by unpaid / pending shipment / assembly not ready
4. **New sale** — pick Buyer, describe Item, set AssemblyStatus, add ComponentChecklist, set price, Payment method, NIF required flag, shipping or pickup, optional photo
5. **Sale detail** — view/edit a Sale, update Payment status, update AssemblyStatus, manage ComponentChecklist, add CTT tracking code
6. **Buyers list** — all saved Buyers
7. **Buyer detail** — view/edit Buyer info, NIF, BuyerAddresses, Sale history
8. **Sales heat map** — postal code heat map of online Sales over Portugal
9. **Settings** — archive/export to Google Drive, import archive, storage usage indicator

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
