# Repository pattern with factory constructors for Demo mode

Every data-access concern is behind an abstract repository interface. `SaleRepository()` and `BuyerRepository()` are factory constructors that return either the Firestore implementation or an in-memory implementation depending on whether Demo mode is active.

## Decision

```dart
abstract class SaleRepository {
  factory SaleRepository() =>
      DemoMode.active.value ? InMemorySaleRepository() : _FirestoreSaleRepository();
  // …
}
```

The Demo/live switch is made exactly once — at construction time, in the factory — and never checked again inside business logic or UI code.

## Considered options

**`if (DemoMode.active.value)` scattered through each method:** The first implementation had this. Every repository method started with a branch. Adding a new method meant remembering to add the branch; forgetting silently wrote to Firestore during a demo session.

**Separate `DemoSaleRepository` class checked at app startup:** Functionally equivalent, but requires the caller (`MainNav`) to know which class to instantiate and to pass it down. The factory approach hides the decision completely — callers just write `SaleRepository()`.

**Feature flag checked in the UI:** Worse separation of concerns; UI should never know which backend is in use.

## Trade-offs to watch

- The factory checks `DemoMode.active.value` at construction time, so toggling Demo mode mid-session (only possible via Settings sign-out) requires a new `MainNav` to be mounted, which happens naturally on sign-out.
- Adding a new data source (e.g. local SQLite offline cache) means implementing the interface and updating the factory — no screen changes needed.
