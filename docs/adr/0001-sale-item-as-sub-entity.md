# SaleItem as a first-class sub-entity of Sale

A Sale can contain multiple physical pieces (e.g. a necklace and a hat in one transaction). We restructured the data model so that each piece is a `SaleItem` with its own description, category, price, assembly status, component checklist, and photos — rather than a single flat set of fields on the Sale.

The Sale total price is derived as the sum of its SaleItems' prices. The Sale-level assembly status is derived as the worst-case status across all SaleItems (a Sale is only `ready` when every SaleItem is `ready`). Payment, shipment, NIF requirement, and notes remain at the Sale level — they describe the transaction as a whole.

## Considered options

**Per-item price vs. single bundle price:** We considered recording one total price per Sale (a negotiated bundle deal), but chose per-item pricing because it enables per-category revenue analytics (e.g. "€100 in Colares this month"), which is a key use case.

**Per-item photos vs. sale-level photos:** We chose per-item photos (stored at `users/{uid}/sales/{saleId}/items/{itemId}/photos/`) so each piece can be photographed independently. The previous sale-level path (`users/{uid}/sales/{saleId}/photos/`) is abandoned; the database was wiped rather than migrated.

**Inline item form vs. sub-screen:** Each SaleItem has enough fields (description, category, price, assembly status, component checklist, photos) to warrant its own screen (`SaleItemScreen`). Nesting that form inline in the sale form would make both screens unusable.
