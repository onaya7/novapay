---
paths:
  - "lib/**/view/**"
  - "lib/**/widgets/**"
---

# Navigation

Routing goes through **go_router**. `lib/app/routes/` holds the whole thing:

- `routes_name.dart` — every `name:` a `GoRoute` answers to, as `static const String`.
- `routes_path.dart` — the matching `path:` strings.
- `routes_generator.dart` — builds the single `GoRouter` (`buildRouter()`), and exposes
  `taskRoutes` (everything that isn't a tab) so a test router can reuse the real destinations.

`AppView` wraps `MaterialApp.router(routerConfig: router)`. `App`'s `_AppState` builds the router
**once** and holds it in a field — building a fresh `GoRouter` inline in `build()` would reset
navigation on every rebuild (a theme toggle, for instance).

## The shell
`AppShell` (`lib/app/view/app_shell.dart`) is built by a `StatefulShellRoute.indexedStack` in
`routes_generator.dart`, one `StatefulShellBranch` per tab (Wallet · Savings · Activity · Profile).
The shell owns which branch is current — there is no cubit duplicating that as separate state.
**A destination that is already a tab is reached by name** (`context.goNamed(RoutesName.savings)`),
never by pushing a second copy of it — that is why the wallet's `Save`/`History` actions and the
Activity section header all call `goNamed` instead of `pushNamed`. Every tab page is a single flat
`GoRoute` with nothing nested under it, so a plain `goNamed` and `StatefulNavigationShell.goBranch`
land on the same place; reach for `goBranch` directly only if a branch ever grows internal route
depth worth preserving.

Tasks — `SendMoneyPage`, `AddMoneyPage`, the NovaSave sub-screens — are `taskRoutes`: top-level
routes pushed over the whole shell with `context.pushNamed(RoutesName.x)`, matching what
`Navigator.push` did before go_router. Pass data a route needs with `extra:`
(`context.pushNamed(RoutesName.contribute, extra: goal)`), read back via `state.extra as T` in the
route's `builder`. `extra` doesn't survive a deep link or a page refresh — this app doesn't claim
either, so that's an accepted trade, not an oversight.

- **A view pushes pages; a widget takes a callback.** `WalletActions` receives `onSend`, it does not
  navigate itself — otherwise a shared widget drags a route into every screen that reuses it.
- `context.pop()` to leave. A screen that owns internal steps intercepts the system back with
  `PopScope(canPop: …, onPopInvokedWithResult: …)` and steps backwards instead of popping, so
  hardware back and the app-bar arrow behave identically.
- The app bar's back button comes from `CustomScaffold`: pass `onBackPressed` to override it, or
  `showBackButton: false` on a root screen or a terminal one such as a receipt.

## Testing
`test/helpers/pump_app.dart`'s `pumpApp` wraps every pumped widget in a real `GoRouter` — carrying
the same tab routes and `taskRoutes` the app ships — rather than a bare `MaterialApp`, so
`context.pushNamed`/`goNamed`/`pop` inside the widget under test resolve exactly as they do in the
app. The pumped widget sits at a **nested** route (`/__pump_app__/widget`), not the router's root:
a plain `context.pop()` on a router's only matched location is a no-op (go_router refuses to pop to
nothing, unlike a bare `Navigator`), so the harness gives it a real parent to pop back to. A test
asserting a flow was "left" checks that the pumped widget's type is gone after popping, the same as
before.

## When a route needs to change
Add the name to `routes_name.dart`, the path to `routes_path.dart`, and the `GoRoute` to
`routes_generator.dart` (a new tab as a `StatefulShellBranch`, anything else as a `taskRoutes`
entry). Nothing else references a path or name string directly.
