# Sales list: active-only default with year chip override

The Sales list shows only active (not-yet-delivered) sales by default. Selecting a year chip lifts this restriction and shows all sales for that calendar year, including delivered ones. Activating a postal-code-prefix scope (geographic view) also lifts the restriction so that delivered shipments to that area are visible.

## Decision

The active-only gate is inferred in `SalesListPresenter._passesScopeFilters`: delivered sales are hidden when `selectedYear == null && postalCodePrefix == null`. There is no explicit flag — entering history mode (selecting a year) or geographic mode (setting a postal prefix) implicitly enables delivered sales.

The timeline groups reflect the current scope:
- **Active mode:** Overdue → This week → Next week → Later → (past months for lingering open sales)
- **Year mode:** Grouped by creation month, newest first

## Why

The seller's daily mental model is a work queue: "what do I still need to act on?" Showing delivered sales by default creates noise that buries the actionable ones. When she explicitly picks a year she is in review/history mode and wants the complete picture.

A custom date range is typically used for a recent window ("show me this month") where the active-only behaviour is still desirable — she is not browsing history, she is filtering the work queue.

## Considered options

**Always show all sales:** Simple to implement. In practice, a seller with 2+ years of history would see hundreds of delivered sales drowning out the 5–10 active ones.

**Separate "History" tab or screen:** Would cleanly separate the two modes. Adds navigation complexity and splits the filtering UI in two. The year chip achieves the same result with less chrome.

**Explicit `activeOnly: bool` flag on the filter model:** More discoverable API but adds a field that callers must set correctly. The inference approach is simpler — the two override conditions (year scope, postal prefix scope) are already present on the model, and their combination fully determines the intent.

**Active-only toggle in the filter sheet:** Explicit but verbose. The year chip as an implicit toggle is more discoverable — the seller reaches for a year when she wants history, and the behaviour matches that intent.
