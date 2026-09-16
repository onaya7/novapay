---
paths:
  - "lib/**/view/**"
  - "lib/**/widgets/**"
---

# Navigation

There is **no router package** in this app. `go_router` is not a dependency and `UiHelpers` does
not exist, so ignore any guidance that assumes them.

Navigation is plain `Navigator`:

```dart
Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => const SendMoneyPage()),
);
```

- **A view pushes pages; a widget takes a callback.** `WalletActions` receives `onSend`, it does not
  navigate itself — otherwise a shared widget drags a route into every screen that reuses it.
- `Navigator.of(context).pop()` to leave. A screen that owns internal steps intercepts the system
  back with `PopScope(canPop: …, onPopInvokedWithResult: …)` and steps backwards instead of
  popping, so hardware back and the app-bar arrow behave identically.
- The app bar's back button comes from `CustomScaffold`: pass `onBackPressed` to override it, or
  `showBackButton: false` on a root screen or a terminal one such as a receipt.

## When a router is added
Introduce `RoutesName` / `RoutesPath` and a `routes_generator.dart` at that point, move every push
behind it, and rewrite this file. Until then, a page constructed inline is the honest shape and
deep linking is not claimed.
