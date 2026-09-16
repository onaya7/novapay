---
paths:
  - "lib/gen/**"
  - "lib/l10n/**"
  - "**/*.g.dart"
  - "**/*.freezed.dart"
  - "**/*.config.dart"
  - "pubspec.yaml"
  - "analysis_options.yaml"
---

# Generated code

**Never hand-edit a generated file.** Change the source annotation and rerun the generator. In
Claude Code, a hook blocks edits to `*.g.dart`, `*.freezed.dart`, `*.config.dart`, `*.gen.dart` and
`lib/l10n/gen/`.

## Git and analysis policy: three different rules

| Output | Generator | Git | Excluded from `analyze` |
|---|---|---|---|
| `*.g.dart`, `*.freezed.dart`, `*.config.dart` | `build_runner` | ignored | yes |
| `lib/l10n/gen/` | `flutter gen-l10n` | ignored | yes |
| `lib/gen/assets.gen.dart`, `lib/gen/fonts.gen.dart` | `flutter_gen` (`build_runner`) | **TRACKED** | **no** |

The third row is the trap.
- `lib/gen/*.gen.dart` doesn't match the `*.g.dart` ignore pattern, so those files are committed.
- **After adding or renaming an asset, rerun codegen and commit the regenerated `assets.gen.dart`.**
  Otherwise CI and every teammate get a missing-getter build break.
- These files aren't excluded from analysis, so a generator upgrade can surface real lint errors.

## Commands
```sh
fvm dart run build_runner build --delete-conflicting-outputs   # freezed, json, retrofit, injectable, hive, flutter_gen
fvm flutter gen-l10n                                            # localization only; a separate step
```

`build_runner` doesn't produce localization output, and `gen-l10n` produces nothing else. A new
string in `lib/l10n/arb/app_en.arb` needs the second command (or a `flutter run`, which triggers it).

## Assets
- Reference assets only through `flutter_gen` (`Assets.images.*.path`), never a hardcoded
  `'assets/...'` string.
- A new asset directory must be declared under `flutter: assets:` in `pubspec.yaml` before it
  generates.

## Dependency overrides
Every `dependency_overrides` entry works around a specific version conflict. Before removing one:
1. Find out why it was added (`git log -S '<package>' -- pubspec.yaml`).
2. Remove it and run `fvm flutter pub get`.
3. Build both platforms.
