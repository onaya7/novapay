# Novapay — agent guide

Where a skill or a general Flutter convention disagrees with this file, this file wins.

## Toolchain
- Flutter is pinned with FVM: `.fvmrc` selects **3.47.2** (Dart 3.13). **Prefix every `flutter` and
  `dart` command with `fvm`.** `.fvmrc` is committed; `.fvm/` is ignored.
- There is no makefile yet. Run a flavor directly:
  `fvm flutter run --flavor development --target lib/main_development.dart`
- Lints: `fvm flutter analyze` **and** `fvm dart run bloc_tools:bloc lint .`. `flutter analyze` does
  not run the bloc rules, and it **exits non-zero on `info`-level issues**, so treat any issue as a
  failure.
- Tests: `fvm flutter test`. Localization: `fvm flutter gen-l10n` (configured in `l10n.yaml`).
- Codegen is not wired yet; there is no `build_runner` dependency. Add it with the first freezed or
  json_serializable source, then `fvm dart run build_runner build`.

## CI gates, all of which fail the build
`.github/workflows/main.yaml` delegates to `very_good_workflows/flutter_package.yml@v1` on
`main`, pinned to `flutter_version: 3.47.x`. CI provisions its own SDK, so its commands are
bare; the `fvm` prefix is for local work only.
- `flutter analyze lib test` — zero issues, `info` included.
- `dart format --set-exit-if-changed lib test` — run `fvm dart format lib test` before pushing.
- `very_good test --min-coverage 100` — **100% line coverage**, not a target.
- `cspell` over `**/*.md` with `modified_files_only: false`. New proper nouns go in
  `.github/cspell.json`.
- `bloc_lint`, and a semantic PR title.

## Money is an integer number of kobo
`lib/core/money/money.dart` is the only place money is parsed, formatted or summed.
- Never `double.parse(x) * 100`: it returns 28 for `'0.29'` and loses a kobo.
- Never `NumberFormat.currency`; it takes a `num` and routes through a double. Format the naira half
  with `NumberFormat.decimalPattern` and join the kobo half as text.
- Goal progress is integer basis points. A `double` appears only at the progress-bar boundary, and
  that boundary is one-way.
- `closeTo` is banned in any money test.

## Architecture
Clean Architecture (`data`/`domain`/`presentation`) with flutter_bloc. `bloc_lint` runs in CI, so
the state-management rules are enforced, not advisory.

- `domain/` imports neither `data/` nor Flutter. Models live in `data/`, entities in `domain/`.
- Presentation calls a **usecase**, never a repository directly.
- Blocs and cubits never import Flutter (`avoid_flutter_imports`).
- **Never import one feature's internals from another.** Promote the shared piece to `core/`.

**Not present yet**, so any rule that references them is aspirational: `ApiClient`, `UiHelpers`,
`AppUrl`/`Env`, and `.env.*` flavor config. `lib/counter/` is Very Good CLI scaffold and gets
deleted when real features land.

## Design system
Tokens live in `lib/config/theme/` (`AppThemeColors`, `TTextTheme`, `AppTheme`) and
`lib/core/constants/` (`AppColor`, `AppSize`). Components live in `lib/core/components/`.
`.claude/rules/ui-conventions.md` lists the ten color roles, the ten type styles and the five
components that exist — **only those exist**, so do not reach for a kit component it does not name.

Two rules that constrain layout rather than decorate it:
- **White on brand is 4.43:1**, so it is legal only at ≥24px or ≥18.66px bold; anything smaller on
  brand uses `primaryStrong`.
- **The system font scale is never clamped**, so every height in `AppSize` is a minimum. Use
  `ConstrainedBox(minHeight:)` on anything containing text.

## Two conventions that will trip a reader
- Widgets import **`package:material_ui/material_ui.dart`**, not `package:flutter/material.dart`.
  Material is a decoupled package as of this Flutter version.
- The Dart 3.13 **`const new({super.key})`** shorthand is used for unnamed constructors. It does
  **not** work for named ones: `const .named(...)` fails to compile, which is why
  `unnecessary_type_name_in_constructor` is disabled in `analysis_options.yaml`.

## Secrets
No `.env` files and no signing material are committed. Tokens and personal data belong in secure
storage, never in Hive or `SharedPreferences`.

## Comments: one line, default to none
Applies to code and tests alike. Explain *why* when it is non-obvious; never restate *what*. Views
carry no comments. Never reference a design-tool node.

## Rules by path: read the rule before editing matching files
Claude Code loads these automatically; other agents must open them.

| When you edit | Read |
|---|---|
| anything in `lib/` or `test/` | `.claude/rules/comments.md` |
| `lib/features/*/data/**`, `lib/features/*/domain/**`, `lib/core/services/**`, `lib/core/network_info/**`, `lib/core/injections/**` | `.claude/rules/data-layer.md` |
| blocs, cubits, `*_state.dart`, `app_bloc_provider.dart` | `.claude/rules/state-management.md` |
| `lib/config/navigators/**`, views, widgets | `.claude/rules/navigation.md` |
| `lib/**/presentation/**`, `lib/core/components/**` | `.claude/rules/ui-conventions.md` |
| `lib/features/**` | `.claude/rules/feature-docs.md` |
| generated output, `lib/gen/**`, `lib/l10n/**`, `pubspec.yaml`, `analysis_options.yaml` | `.claude/rules/generated-code.md` |

## Skills
Installed per agent rather than stored here: `add-feature`, `add-route`, `paginate-list`,
`add-picker-sheet`, `codegen`, `ship-flavor`.

## Git
Conventional Commits. CI runs on `main`. `docs/*.pptx` is generated and git-ignored.

## Keeping this file current
When you establish a reusable pattern, convention or load-bearing architectural fact, record it in
the narrowest place that fits: a `.claude/rules/` file if it is path-specific, this file only if
every session needs it. One line with a source path. Delete anything that becomes wrong. If every
future app should get the change, use the `update-kit` skill.
