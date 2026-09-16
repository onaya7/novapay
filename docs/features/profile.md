# Profile

## Purpose
Who is using this device. There is no auth in this build, so identity is a single locally-stored
display name — nothing here is claimed to have come from a server. It backs both the Profile tab
and the wallet's greeting, and it holds the theme toggle.

## Entry screens
`ProfilePage` (`lib/features/profile/presentation/view/profile_page.dart`) is the fourth tab behind
`AppShell`'s bottom nav. Unlike the other tabs it does not resolve its own cubit — `ProfileCubit` is
app-wide (`@lazySingleton`) and started once by `App`, because the wallet's greeting reads the same
name the profile screen edits.

## Endpoints
None. Everything here is local: `ProfileRepositoryImpl` reads and writes `LocalDataStorage` under
`StorageKeys.displayName`, never a network call.

## State
`ProfileCubit` — a sealed `ProfileState` of `loading` · `ready(UserProfile)` · `failure(message)`.
Not paginated. `start()` loads once; `rename(name)` saves and re-emits `ready`. Also relevant:
`ThemeCubit` (`lib/app/presentation/cubit/theme_cubit.dart`, `@lazySingleton`), which the Profile
screen's `ThemeModeToggle` reads and writes, and which restores **in its constructor** so there is
no flash of the wrong theme on launch.

## Key files
1. `domain/entities/user_profile.dart` — `hasName`, `greetingName` (falls back to `'Wallet'`,
   never a fabricated name), `initials`.
2. `data/repositories/profile_repository_impl.dart` — the only place that touches
   `StorageKeys.displayName`.
3. `presentation/cubit/profile_cubit.dart` — load-once, rename-and-reload.
4. `presentation/view/profile_page.dart` — avatar, name field, Settings (theme, About).
5. `presentation/widgets/profile_widgets.dart` — `SettingsRow`, `SettingsGroup`,
   `ThemeModeToggle`.

## Gotchas
- **`ProfileState.profile` returns an empty `UserProfile` on the base class, overridden by `ready`'s
  field.** A `switch` reaching for a shared `profile` getter on every variant is dead code the same
  way `ContributeState.draft` is — see `docs/features/savings.md`.
- **`ProfileCubit.start()` is called once, by `App`, not per screen.** Two places read the same
  cubit (the wallet header and the Profile tab); starting it again per screen would refetch for no
  reason and risk two racing writes if a rename was mid-flight.
- **The display name is never sent anywhere.** It lives in `LocalDataStorage` (Hive), not secure
  storage, because it is a preference, not a credential.
- **The avatar photo is a tracked asset, referenced only through `flutter_gen`.** `AppAvatar` takes
  an optional `ImageProvider? image`; the wallet header and the Profile screen both pass
  `Assets.images.profile.provider()`. Nothing hardcodes the asset path string, and nothing reaches
  for `UserProfile.initials` — it stays unused until a device with no saved photo needs a fallback
  that isn't the generic icon.
