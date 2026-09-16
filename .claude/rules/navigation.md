---
paths:
  - "lib/config/navigators/**"
  - "lib/**/view/**"
  - "lib/**/widgets/**"
---

# Navigation: always through `UiHelpers`

Never route directly from feature or widget code. Use `UiHelpers`
(`lib/core/helpers/ui_helpers.dart`):

| Instead of | Use |
|---|---|
| `context.go(RoutesPath.X)` | `UiHelpers.replaceStack(context, RoutesName.X)` |
| `context.pushNamed(...)` / `GoRouter.of(context).pushNamed(...)` | `UiHelpers.navigateTo(context, RoutesName.X, extra: e)` |
| push-replacement | `UiHelpers.replace(...)` |
| `Navigator.pop(context[, result])` | `UiHelpers.pop(context[, result])` |

`UiHelpers` also provides:
- `navigateForResult<T>`, which awaits the pop result
- `datePicker` and `timePicker`
- `pickImage` and `pickFile`
- `showConfirmDialog`
- haptics, share and clipboard helpers

**Leaving the app:** use `UiHelpers.openExternalUrl(url, context:)` for destinations the app doesn't
host. URLs live in `lib/core/constants/app_links.dart`, never inline.

- Always pass `RoutesName.*`, never `RoutesPath.*`. `UiHelpers.pop` works for screens, bottom sheets
  and dialogs, and forwards the result.
- **Exceptions:**
  - `UiHelpers`' own internal `Navigator.pop`, which is the source of truth.
  - `Navigator.canPop()`, which is a query.
  - An explicit `Navigator.of(context, rootNavigator: true).pop()` for root-level loading dialogs.

## Routes
- Every route defines both a `RoutesName` (go_router *name*, `routes_names.dart`) and a `RoutesPath`
  (URL *path*, `routes_path.dart`). You navigate by **name**.
- The router is built in `lib/config/navigators/routes_generator.dart`.
- The bottom-nav shell is a `StatefulShellRoute.indexedStack` rendered by `CustomNavigationBar`.
  - Branch children use **relative** paths: `'details'` under the home branch becomes `/home/details`.
  - Cross-tab overlays and detail screens are **top-level** routes with absolute paths.
  - An overlay that should hide the nav bar adds its path prefix to `hideNavRoutePrefixes`.
- **A screen on a top-level route may only push top-level routes.**
  - go_router merges a push into the existing shell only when the stack's last match is that shell.
  - Pushing a shell child while a top-level route is on top builds a second shell page with the
    same key, which trips Navigator's `!keyReservation.contains(key)` assertion.
  - A screen reachable at both kinds of route is bound by the stricter rule.
- Typed `extra` objects survive state restoration only if their type is registered in
  `AppExtraCodec` (`app_extra_codec.dart`).
- The base app has no auth redirect. If one is added, sign-up wizard routes belong in both the
  public set and the signed-out-only set, and a screen for already signed-in users belongs in
  neither. Getting this wrong breaks the route in exactly one auth state.
