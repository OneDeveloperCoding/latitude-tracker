# Latitude Tracker

A private mobile app for a solo artisan seller in Portugal to track sales, payments, and shipments for unique handmade accessories (necklaces, earrings, tote bags, hats). Sold primarily through Instagram DMs and in-person at events. Used on two devices (phone + tablet) under a single account.

## Language

**Sale**:
A transaction where one or more Items are sold to a Buyer at an agreed price.
_Avoid_: Order, purchase, transaction

**Buyer**:
A person who purchases Items, identified by name and optionally an Instagram handle or phone number. A Buyer persists across multiple Sales.
_Avoid_: Customer, client, user

**BuyerAddress**:
A named shipping address belonging to a Buyer (e.g. "Home", "Work"). A Buyer may have multiple BuyerAddresses; one may be marked as default.
_Avoid_: Delivery address, shipping address (as a standalone concept)

**Item**:
A unique, one-of-a-kind physical product (e.g. necklace, earring, tote bag, hat). Not tracked as inventory — only recorded as part of a Sale.
_Avoid_: Product, SKU, stock

**Payment**:
Money received (or owed) for a Sale. Has a status (paid / unpaid) and a method (MB Way, cash, SumUp card, bank transfer).
_Avoid_: Invoice, charge

**Shipment**:
The physical delivery of Items from a Sale to a Buyer. Has a status (pending / shipped / delivered) and optionally a CTT tracking code. References a BuyerAddress if shipped.
_Avoid_: Delivery, fulfillment, dispatch

**Dashboard**:
A summary screen showing total revenue for the current month, number of unpaid Sales, and number of pending Shipments.
_Avoid_: Report, analytics, overview

**Archive**:
A read-only export of Sales data and associated photos for a given period, saved to the seller's Google Drive. Can be re-imported into the app for historical lookup only.
_Avoid_: Backup, dump

## Relationships

- A **Sale** belongs to exactly one **Buyer**
- A **Sale** has one **Payment** (which may be unpaid)
- A **Sale** has one **Shipment** OR is marked as in-person pickup (no Shipment needed)
- A **Shipment** references one **BuyerAddress**
- A **Sale** may have one or more photos attached (compressed to max 1200px / ~500KB before upload)
- A **Buyer** may have multiple **Sales** over time
- A **Buyer** may have multiple **BuyerAddresses**; one is marked as default
- An **Archive** is read-only — Sales and photos cannot be edited after archiving

## Example dialogue

> **Dev:** "When she creates a Sale for a returning Buyer, does the address auto-fill?"
> **Domain expert:** "Yes — it should pre-fill with the Buyer's default BuyerAddress, but she should be able to pick a different one or add a new one on the spot."

> **Dev:** "When she records a Sale, does the Shipment get created at the same time?"
> **Domain expert:** "Yes — she marks it as shipping or in-person pickup at the point of sale. If shipping, she fills in the CTT tracking code later when she drops it off at CTT."

> **Dev:** "Can archived Sales be edited after import?"
> **Domain expert:** "No — Archives are historical records. Read-only on re-import."

## Flagged ambiguities

- "order" was used informally — resolved to **Sale** to avoid confusion with e-commerce order management concepts.
- "address" initially assumed one per Buyer — resolved to **BuyerAddress** supporting multiple per Buyer with a default.
