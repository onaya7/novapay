# Wallet

## Purpose
The home screen. Shows what the customer can actually spend, what is still in flight, and a single
activity list that merges settled transactions with money still sitting in the local queue.

## Entry screens
`WalletPage` (`lib/features/wallet/presentation/view/wallet_page.dart`) is the app's `home`. It
resolves `WalletCubit` from the container and starts it; `WalletView` renders. There is no router
yet, so nothing navigates away from it.

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
5. `presentation/widgets/wallet_widgets.dart` — balance card, activity row, skeleton.

## Gotchas
- **A `done` action is skipped in the merge.** Once the queue settles an action the server owns it,
  so including both would list the same transfer twice.
- **Queued amounts are negated on the way in.** `PendingAction.amountKobo` is a positive magnitude;
  the activity list needs a signed number, and money leaving is negative.
- **`available` is allowed to go negative.** Clamping it would hide an over-commitment instead of
  showing it. The guard that prevents over-commitment belongs at enqueue, and is not built yet.
- **A refused read throws `AppException`, it does not return null.** `_unwrap` turns an error
  `ApiResponse` into the app's error vocabulary so `EitherSafeRunner` can map it to a `Failure`.
  Reading `requireData` off an error response would throw `StateError`, which is an `Error` and
  would escape the runner deliberately.
- **`WalletRepositoryImpl` depends on `SyncService`, not the other way round.** The queue knows
  nothing about the wallet screen.
