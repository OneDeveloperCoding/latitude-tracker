# State management with ValueNotifier and streams

The app uses `ValueNotifier<T>` and Dart `Stream`s as its sole state management primitives — no external package (Provider, Riverpod, Bloc, etc.).

## Decision

Global app state is held in `SalesStore` and `BuyersStore` (`lib/core/store/`), each a `ValueNotifier<StoreState<T>>` that wraps a repository stream. Screens listen via `ValueListenableBuilder` or call `context.watch` equivalents. Per-entity live streams (`watchSale(id)`, `watchSalesForBuyer(id)`) are opened directly in screens that need them via `StreamBuilder`.

## Considered options

**Provider / Riverpod:** The dominant Flutter community choices. Both add real value on large teams or apps with complex dependency graphs. Here the app has two stores and no widget-to-widget dependency injection needs; wrapping `ValueNotifier` in a provider just adds a build-step layer with no return.

**Bloc / Cubit:** Explicit events and state transitions are valuable when business logic is complex or must be unit-tested in isolation. For this app the logic lives in service classes and pure functions (`SaleUrgency`, `SaleGrouper`, `DashboardStats`) — there is nothing left for a state machine to manage.

**ValueNotifier + streams (chosen):** Zero dependencies, works identically across Flutter versions, and the pattern is directly readable to any Flutter developer. `StoreState<T>` (a sealed class with `StoreLoading`, `StoreLoaded`, `StoreError`) captures the same loading/error/data triangle that any state package would provide, without the package.

## Trade-offs to watch

- No automatic disposal of listeners — each `ValueListenableBuilder` and `StreamBuilder` must be placed where its widget lifetime manages the subscription. So far this has not been an issue because screens are the only subscribers.
- If a third store is needed (e.g. a `SettingsStore`), the pattern extends trivially by copying `SalesStore`.
