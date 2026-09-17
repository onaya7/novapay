# Wallet

## Purpose
The home screen. Shows what the customer can actually spend, what is still in flight, and a single
activity list that merges settled transactions with money still sitting in the local queue.

## Entry screens
`WalletPage` (`lib/features/wallet/presentation/view/wallet_page.dart`) is the first of the four tabs
behind `AppShell`'s bottom nav (Wallet · Savings · Activity · Profile). It resolves `WalletCubit`
from the container and starts it; `WalletView` renders. Its quick actions push `SendMoneyPage` and
`AddMoneyPage` (`context.pushNamed`), and switch tab (`context.goNamed`) for Save and History rather
than pushing a second copy of a screen that already exists as a tab. `TransactionDetailPage`
(`presentation/view/transaction_detail_page.dart`) is pushed from a tap on any `ActivityRow`, here
and on the Activity tab alike, carrying the tapped `ActivityItem` as router `extra`.

## Endpoints
Through `NovaPayApi`, never a repository call from the UI:

| Call | Used for |
|---|---|
| `balance()` | the confirmed number, which is never computed on the client |
| `transactions()` | the settled half of the activity list |

The pending half comes from `SyncService.actions()` and `SyncService.pendingKobo()`.

## State
`WalletCubit` — a sealed `WalletState` of `loading` · `ready(WalletSnapshot)` · `failure(String)`.
Not paginated. It loads once through `LoadWallet`, then subscribes to `WatchWallet` so a queued
send appears without a reload. `refresh()` backs pull-to-refresh and the error retry.

## Key files
1. `domain/entities/wallet_snapshot.dart` — where `available = confirmed − pending` is decided.
2. `data/repositories/wallet_repository_impl.dart` — the merge, and the envelope-to-`Failure` bridge.
3. `presentation/cubit/wallet_cubit.dart` — load-once-then-follow.
4. `presentation/view/wallet_page.dart` — the three states.
5. `presentation/view/activity_page.dart` — the full history, reading the same `WalletCubit`
   snapshot as the wallet's recent list. It lives here rather than as its own feature because a
   separate feature would mean importing this one's internals from another.
6. `presentation/view/transaction_detail_page.dart` — a pure display of one `ActivityItem`, no
   cubit of its own.
7. `presentation/widgets/wallet_widgets.dart` — header, balance card, actions, activity row,
   skeleton.
8. `presentation/view/wallet_page_golden_test.dart` (in `test/`) — the loading, empty and populated
   states, light and dark, rendered with `alchemist`'s CI font so the golden is stable off this
   machine too. Run `fvm flutter test --update-goldens` after any visual change to this screen.

## Gotchas
- **A `done` action is skipped in the merge.** Once the queue settles an action the server owns it,
  so including both would list the same transfer twice.
- **Queued amounts are negated on the way in.** `PendingAction.amountKobo` is a positive magnitude;
  the activity list needs a signed number, and money leaving is negative.
- **`available` is allowed to go negative.** Clamping it would hide an over-commitment instead of
  showing it. The guard that prevents one lives at enqueue, in `TransferRepositoryImpl.queue`.
- **A refused read throws `AppException`, it does not return null.** `_unwrap` turns an error
  `ApiResponse` into the app's error vocabulary so `EitherSafeRunner` can map it to a `Failure`.
  Reading `requireData` off an error response would throw `StateError`, which is an `Error` and
  would escape the runner deliberately.
- **`WalletRepositoryImpl` depends on `SyncService`, not the other way round.** The queue knows
  nothing about the wallet screen.
- **The header greets a name when one exists, and the surface when it doesn't.** There is still no
  auth, so the name is `ProfileCubit`'s locally-stored `displayName`, read via
  `UserProfile.greetingName`; with nothing saved it falls back to `Wallet` rather than fabricating a
  name. The greeting word itself is real — derived from the clock by `DateTimeX.greeting`.
- **`WalletPage` reads the app-wide `ProfileCubit` rather than creating one.** It is provided above
  the shell by `App`; a screen resolving its own copy would show a stale name the moment the profile
  screen changed it. Which tab is current is owned by the `StatefulShellRoute` itself, not a cubit —
  see `.claude/rules/navigation.md`.
- **Hiding the balance is local widget state and is not persisted.** It protects against someone
  reading over a shoulder, which is a per-glance concern, not a stored preference.
- **All four quick actions are live.** `More` is gone; `Add money` opens the real funding flow.
  `Save` and `History` switch tab instead of pushing, because both destinations already exist as
  tabs and a push would leave a second copy on the stack.
- **Every `ActivityRow` is tappable**, wrapped in its own `Material`/`InkWell` per the shared-widget
  convention, opening `TransactionDetailPage`. A settled row's detail is limited to what
  `ActivityItem` carries (title, amount, date, status) — settled transactions don't retain the
  original `PendingAction.payload`, so a bank/account beyond what's already baked into the title
  isn't available for those rows.
- **A queued send's title names the bank when one was chosen.** `_titleFor` reads `bankName` out of
  the pending action's payload and falls back to the pre-bank `'To $recipient'` format when it's
  absent, so older queued or settled rows still read correctly.
- **The shell's bottom nav is opaque, not translucent**, so neither list needs bottom-inset padding
  beyond its own static values — see `.claude/rules/ui-conventions.md`.
