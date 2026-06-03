# Localisation via a manual AppStrings class

All UI strings live in a single `AppStrings` class (`lib/core/l10n/app_strings.dart`) constructed with a boolean (`_pt`). Every string is a typed `final` field. Access is via `context.s` — an extension on `BuildContext` that reads the nearest `AppLocaleScope` `InheritedWidget`.

## Decision

```dart
class AppStrings {
  AppStrings(bool pt) : _pt = pt;
  final bool _pt;
  String get sales => _pt ? 'Vendas' : 'Sales';
  // ~230 fields, plural helpers, enum label methods
}

// In any widget:
context.s.sales
```

`AppLocaleScope` is an `InheritedWidget` that wraps the entire app tree. Any widget that calls `context.s` automatically registers a dependency on it, so the whole tree rebuilds instantly on language toggle — no `ValueListenableBuilder` wrapper at each call site.

## Considered options

**`flutter_localizations` + `.arb` files + `flutter_gen`:** The standard Flutter approach. Generates type-safe accessor classes from ARB files. Requires `build_runner` in dev dependencies, generated files committed or run in CI, and a separate toolchain for translators. For a two-language, single-developer app this is significant overhead with no benefit.

**`intl` package with `Intl.message()`:** Adds ICU message format support. Useful for complex pluralisation rules in many languages. With only PT and EN, Dart's ternary (`_pt ? '…' : '…'`) handles every case, including plurals (the `AppStrings` class has dedicated plural helper methods).

**AppStrings as a manual class (chosen):** Zero generated code, zero build step, fully navigable in the IDE, and type errors surface at compile time. The `InheritedWidget` propagation means there is no performance difference versus a generated solution.

## Trade-offs to watch

- Adding a third language means extending the constructor and every field — there is no ARB file to hand to a translator. Acceptable at two languages; revisit if a third is ever needed.
- `AppStrings` is already ~1,200 lines. Keep it organised by section comments if it grows further.
