# Changelog

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
