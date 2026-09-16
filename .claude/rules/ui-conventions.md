---
paths:
  - "lib/**/presentation/**"
  - "lib/core/components/**"
  - "lib/config/theme/**"
---

# UI conventions

Only the components listed below exist. **Do not import one that isn't in this file** — build it
here, or promote it from a feature once a second caller wants it.

## Colors: which layer a value belongs to
Two layers, split by whether the value changes between light and dark:

- **Mode-varying:** a semantic role on `AppThemeColors` (`lib/config/theme/app_theme_colors.dart`).
- **Mode-invariant:** a primitive on `AppColor` (`lib/core/constants/app_color.dart`).

**Never branch on `Theme.of(context).brightness` to pick a color.** An `isDark ? a : b` pair is a
semantic role nobody has named yet, so add the field instead.

No raw `Color(0x..)` or `Color.fromARGB(...)` in a widget. Use `AppColor.white`/`AppColor.black`,
not `Colors.white`/`Colors.black`. `Colors.transparent` stays inline.

The ten roles, read as `context.colors` or `AppThemeColors.of(context)`:
`primary`, `primaryStrong`, `background`, `cards`, `fill`, `divider`, `textHeading`,
`textSubheading`, `subtext`, `warning`. `success` and `danger` are invariant and live on `AppColor`.

`test/config/theme/app_theme_colors_test.dart` pins every role in both modes. Change an expected
value there only because the design changed, never to make the test pass.

### Contrast rules the palette forces
- **White on `primary` is 4.43:1**, under AA. Legal only at ≥24px, or ≥18.66px bold — in practice
  the balance figure and a primary CTA label. Anything smaller on brand uses `primaryStrong`.
- **Never `subtext` or `textSubheading` on `fill` in dark**: 3.25:1 and 4.47:1, both fail. Put them
  on `background` or `cards`.
- Text on brand binds `AppColor.onBrand`, never an inverse role that flips with the mode.

## Typography
Ten styles on the standard `TextTheme` (`lib/config/theme/custom_theme/text_theme.dart`), read as
`context.texts`. `bodyMedium` (14/22) is the default. **Nothing renders below 10px, and nothing
essential below 12px** — `labelSmall` is for non-essential metadata only.

No `fontFamily` is set. The platform face costs no download on a low-end device, and the ramp is
defined by size and weight so a brand typeface can be added later without retuning the layout.

**The app respects the system font scale and never clamps it.** That makes every height in
`AppSize` a *minimum*: use `ConstrainedBox(minHeight:)`, never `SizedBox(height:)`, on anything
containing text. No `maxLines: 1` on a label that carries meaning; wrap rather than truncate.

## Spacing
`AppSize` (`lib/core/constants/app_size.dart`) holds the 4pt scale, radius (`radiusSm` 10,
`radiusLg` 16, `radiusPill`), the 16/20/24 icon ramp and `touchTarget` 44. Gaps are
`AppSize.h(n)` / `AppSize.w(n)`.

## Components that exist
All in `lib/core/components/`.

| Need | Use |
|---|---|
| Screen shell: SafeArea, page padding, app bar, pinned CTA | `CustomScaffold` |
| Any button | `CustomButton` (`primary` / `secondary` / `plain`) |
| Pending, Sent or Rejected state on a row | `StatusChip` |
| Any amount of money on screen | `MoneyText` |
| Spinner, skeleton, error, empty, pull-to-refresh body | `state_widgets.dart` |

- **Scaffolds:** wrap every screen in `CustomScaffold`, never a bare `Scaffold`. A pinned CTA goes
  in `bottomBar:`, never in a `Column` with an `Expanded` above it — that overflows into the button
  as soon as the keyboard opens.
- **A view file holds only its view.** Sub-widgets move to the feature's `presentation/widgets/`,
  grouped in one `<view_stem>_widgets.dart`; a widget two views share gets its own file.
- **Public widget first**, with its one `///` line; private helpers below, undocumented.

## Interaction and state
- One primary CTA per screen; secondary actions are visually subordinate.
- **Buttons name the action**: `Send ₦5,000.00`, `Fund Wallet`, `Create goal` — never `Continue`,
  `Proceed` or `Submit`.
- **Disabled is `fill` + `subtext`**, never brand at reduced opacity, which reads as a rendering
  fault in dark mode. `CustomButton` already does this; don't override it.
- A CTA must not look live when required input is empty. But a *blocked* screen keeps a live CTA
  that fixes the problem — on insufficient funds the button becomes `Fund Wallet`, because a
  disabled control there is a dead end rather than a state.
- **Any wait over 300ms gets a `SkeletonBox` shaped like the final layout**, never a bare spinner on
  a data screen and never a blank one.
- Error copy is three beats — what happened, what it means, what to do — and never a raw error code.
- Micro-interactions 150–300ms; exit ~60–70% of enter. Press feedback must not shift layout bounds.

## Money and accessibility
- **Never render an amount with a bare `Text`.** `MoneyText` announces it as words, because a screen
  reader reads raw currency text as "naira two comma four eight zero".
- Every icon-only control gets a 44pt frame and a label or tooltip.
- Inputs carry a **visible label and** a semantic one; placeholder-only labeling is a defect.
- A state change — queued becoming sent, a validation error appearing — is announced, not left as a
  silent color change.

## Lists
`ListView.builder` for anything unbounded, with a `ValueKey` per row so state survives reordering.
Never `Column` inside `SingleChildScrollView` for a list that grows.
