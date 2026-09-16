---
paths:
  - "lib/**/presentation/**"
  - "lib/core/components/**"
---

# UI conventions

## Colors: which layer a value belongs to
There are two layers, split by whether a value changes between light and dark mode:

- **Mode-varying:** a semantic role on `AppThemeColors` (`lib/config/theme/app_theme_colors.dart`).
- **Mode-invariant:** a primitive on `AppColor` (`lib/core/constants/app_color.dart`).

**Never branch on `Theme.of(context).brightness` to pick a color.** An `isDark ? a : b` pair is a
semantic role nobody has named yet, so add the field instead.

No raw `Color(0x..)` or `Color.fromARGB(...)` literals. Use `AppColor.white`/`AppColor.black`, not
`Colors.white`/`Colors.black`.

- If a color isn't defined yet, add it to the layer that fits, and reuse an existing constant when
  the hex already matches.
- A gradient reused across files belongs in `AppGradient` (`lib/core/constants/app_gradient.dart`).
- **Exceptions that stay inline:** one-off gradient lists, image scrims, `Colors.transparent`, and
  throwaway shimmer greys.

## Theme-aware surfaces
`AppThemeColors.of(context)` exposes: `textHeading`, `textSubheading`, `subtext`, `textLink`,
`background`, `cards`, `cardFill`, `stroke`, `strokeFill`, `fill`, `divider`, `modalSurface`,
`icon`, `iconBg`, `iconLow`, `iconInactive`, `primary`.

**Never give a sheet or surface a fixed light constant as its background** (such as
`AppColor.white`). It stays light in dark mode while theme text turns light, and the content becomes
invisible. Use `.cards` or `.background`.

The theme test in `test/config/theme/` pins every role in both modes. Change an expected value there
only because the design changed, never just to make the test pass.

## Structure
- **Scaffolds:** wrap every screen in `CustomScaffold` (`lib/core/components/custom_scaffold.dart`),
  never a bare `Scaffold`; it standardizes SafeArea, padding and the app bar. Full-bleed or overlay
  screens pass `safeArea: false, padding: EdgeInsets.zero`.
- **A call-to-action pinned below flexible content:** use `PinnedActionLayout`
  (`lib/core/components/pinned_action_layout.dart`), never a bare
  `Column(children: [Expanded(...), CustomButton(...)])`. That overflows into the button as soon as
  the keyboard opens.
- **A view file holds only its view:** the widget and its `State`. Sub-widgets, data classes and
  formatters move to the feature's `presentation/widgets/`, or to `core/` once a second feature wants
  them.
- **Group by view, not by widget:** a view's extracted widgets go in one
  `<view_stem>_widgets.dart` (split it past about 250 lines). A widget shared by two or more views
  gets its own file named after it.
- **Public widget first:** in a widget file, the exported class comes first with a one-line `///`;
  private helpers go below, undocumented. Sheets and dialogs invert this: a public `show*()` function
  or `static show()` on top, the private widget below.
- **Text input:** always `CustomInputField` (`lib/core/components/custom_inputfield.dart`), never a
  raw `TextField`/`TextFormField`.
  - Pass `variant:` for a look the input theme can't express.
  - Keyboard dismissal is already global through `KeyboardDismissal`, installed once on the root
    `MaterialApp`.
  - Chain `currentFocus`/`nextFocus` only across a multi-field form, never on a multiline field; it
    replaces the newline key.
- **Phone input:** `PhoneNumberField` with a `PhoneCountry` (`lib/core/helpers/phone_country.dart`).
  Never hand-roll a dial code, digit cap or grouping mask. `PhoneCountry` owns validation, the mask,
  `toE164` for payloads and `toNational` for display.
- Before writing a new widget, check `lib/core/components/`. Before writing pickers or dialogs, check
  `lib/core/helpers/ui_helpers.dart`.

## Shared widgets to reach for
All of these live in `lib/core/components/`. Use them instead of a raw Flutter widget.

| Need | Use |
|---|---|
| On/off toggle | `AppSwitch` |
| Chip: toggleable, with a count badge, or the pill beside a search field | `SelectionChip`, `CountFilterChip`, `FilterPill` |
| Tabs inside a screen | `SegmentedTabBar` |
| Radio control, dot alone or with its label | `RadioDot`, `RadioOption` |
| Star rating input | `RatingStars` |
| Search entry point that opens a search screen | `SearchBarField` |
| Row showing a value or placeholder that opens a picker | `PickerLauncher` |
| Tap-to-pick date field | `DatePickerField` |
| Currency amount | `MoneyInputField`, with `MoneyInputFormatter.unformat` before sending |
| Label above a field or section | `FieldLabel` |
| Avatar, falling back to initials | `UserAvatar` |
| Remote raster image | `CustomCachedImage` (`NetworkSvgIcon` for SVG) |
| Gradient emphasis text | `GradientText` |
| Tap target with an ink ripple | `CustomRipple` |
| Dashed outline, such as an upload box | `CustomDashedBorderPainter` inside a `CustomPaint` |
| Centered dialog chrome | `DialogFrame` |
| Grab handle in a bottom sheet | `SheetHandle`, placed inside the sheet, never over the scrim |

## Feedback and state
- **Toasts, not snackbars:** `UiHelpers.showToast(message, status: ToastStatus.x)`.
- **Blocking loader:** `UiHelpers.showLoader()` / `hideLoader()`, a ref-counted app-wide overlay.
  Pair the calls in `try`/`finally`; never use a per-call `showDialog` spinner.
- **List and async screens:** `LoadingIndicator`, `AppErrorState(onRetry:)` and `AppEmptyState`
  (`lib/core/components/state_widgets.dart`).
- **Confirmations and outcomes:** `showFeedbackSheet(...)` (`lib/core/components/feedback_sheet.dart`).

## Misc
- **Assets:** `flutter_gen` only (`Assets.images.*.path`).
- **Remote SVGs** go through `NetworkSvgIcon`. Image widgets that decode to an `ImageProvider` can't
  read SVG. Always pass a fallback icon.
- **Spacing:** `AppSize.h(n)` / `AppSize.w(n)` (`lib/core/constants/app_size.dart`).
- **`UiHelpers.datePicker` defaults `lastDate` to now,** which blocks every future date. Pass an
  explicit `lastDate` on any forward-looking picker, and work in `DateUtils.dateOnly` values.
- **Comments:** see `.claude/rules/comments.md`. Views carry none.
