---
paths:
  - "lib/**/bloc/**"
  - "lib/**/cubit/**"
  - "lib/**/*_state.dart"
  - "lib/app/presentation/view/app_bloc_provider.dart"
---

# State management

## State shape
State classes are freezed **sealed** unions with `initial` / `loading` / `success(data)` /
`error(message)`, plus `loadingMore` when the list is paginated:

```dart
@freezed
sealed class OrdersState with _$OrdersState {
  const factory OrdersState.initial() = _Initial;
  const factory OrdersState.loading() = _Loading;
  const factory OrdersState.success(List<Order> data) = _Success;
  const factory OrdersState.error(String message) = _Error;
}
```

A cubit emits `loading`, awaits the usecase, then folds the result:

```dart
result.fold(
  (f) => emit(OrdersState.error(ConvertFailureToString(f))),
  (d) => emit(OrdersState.success(d)),
);
```

In the UI, branch with `.when` / `.maybeWhen` / `.whenOrNull`, **never** `switch` or `is`. Other
layers, such as a router redirect or a Dio interceptor, may use `switch` and `is` freely.

## Registration and lifetime
- Annotate blocs and cubits `@lazySingleton`.
- Register each one in `lib/app/presentation/view/app_bloc_provider.dart` as
  `BlocProvider<T>.value(value: sl<T>())`. Singletons are what let a multi-screen wizard keep its
  state.
- Because cubits live as long as the app, a cubit holding per-screen state (a search query,
  filters, a selection) exposes `reset()`, and the screen calls it from `initState`.
- Cache the raw server data in the cubit and derive filtered or sorted lists at emit time. Don't
  overwrite the cache with a filtered copy.
- Every singleton that holds user data must be cleared on sign-out.

## bloc_lint rules: `flutter analyze` does NOT catch these
`analysis_options.yaml` includes `package:bloc_lint/recommended.yaml`, but those rules live under a
`bloc:` key the Dart analyzer ignores. Run them explicitly:

```sh
fvm dart run bloc_tools:bloc lint .
```

The CLI prints its own update prompt *after* the result, so read the `N issues found` line above
that box rather than the tail of the output.

| Rule | Meaning |
|---|---|
| `avoid_flutter_imports` | No `package:flutter/*` import in a bloc or cubit. Use framework-agnostic types (for example an `AppThemeMode` enum and a `String languageCode`) and convert at the `MaterialApp` boundary. |
| `avoid_public_bloc_methods` | Blocs communicate through events, not public methods. |
| `avoid_public_fields` | No mutable public fields on a bloc or cubit; state goes in the state class. |
| `prefer_file_naming_conventions` | `*_bloc.dart`, `*_event.dart`, `*_state.dart`, `*_cubit.dart`. |
| `prefer_void_public_cubit_methods` | Public cubit methods return `void` or `Future<void>`; results are emitted as state. |

CI runs these, so a violation fails the build even when `flutter analyze` passes locally.

A fresh app reports zero bloc_lint warnings. Public pagination getters such as `hasMore` and
`cachedData` trigger `prefer_void_public_cubit_methods`, because the rule can't tell a getter from a
method. Those warnings are expected; leave them. Any other warning is new, and yours to fix.

## Pagination
When a list endpoint's response carries `totalPages`/`totalElements`, implement incremental loading
instead of stopping at page 1. Follow the `paginate-list` skill.
