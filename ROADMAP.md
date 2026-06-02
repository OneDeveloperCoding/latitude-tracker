# Roadmap

Planned improvements and features for latitude-tracker, roughly in priority order.

---

## Monitoring & Analytics

**Firebase Performance Monitoring + Analytics**

Add visibility into app performance and usage patterns.

- Auto screen tracking via `FirebaseAnalyticsObserver` on the router
- Performance traces around key operations (e.g. sales list load)
- Key events: `sale_created`, `filter_applied`

Already on Firebase (Firestore), so no new accounts needed. Packages: `firebase_performance`, `firebase_analytics`.

---

## Dashboard

**Layout revamp**

The current dashboard is a vertical list — revenue card followed by action rows. Explore a richer layout that makes better use of screen real estate and gives more at-a-glance insight.

Ideas to explore:
- Summary stat chips (total sales, avg order value) below the revenue card
- Sparkline or mini bar chart for revenue trend across the last N periods
- Group action rows visually (e.g. "money" vs "logistics" vs "compliance")
- Quick-action FAB or swipeable shortcuts for common tasks

**Period-scoped action counts (optional)**

Currently "Action needed" counts (unpaid, overdue, etc.) always reflect global current state regardless of the selected period — this matches what the destination screens show. A future option would be a toggle to show only actions from sales created within the selected period, e.g. "unpaid sales from this week". Requires passing period bounds into action count logic and filtering destination screens accordingly.

---

## Testing

**Tier 2 — Repository tests (Firestore-backed)**

Unit-test `SaleRepository` and `BuyerRepository` against a real in-memory Firestore instance.

- Add `fake_cloud_firestore` to `dev_dependencies`
- Test CRUD operations: create, read, update, delete
- Test stream emissions (`watchSale`, `watchAddresses`) on data changes
- Test `getSalesForBuyer` filtering

**Tier 3 — Widget tests**

Smoke-test key screens to catch widget-tree regressions.

- `SalesListScreen`: renders with empty store, renders with a loaded list
- `_SaleCard`: correct accent bar on urgency, correct badges (NIF, urgency)
- `BuyerDetailScreen`: tabs present, info section above tabs
- `AddressFormFields`: postal code lookup triggers spinner, single-street auto-fills, multi-street shows picker

---
