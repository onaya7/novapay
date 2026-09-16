# Add money

## Purpose
Top up the wallet. Reuses the offline-queue shape everything else here uses, rather than treating
"money coming in" as special: written to the local queue before any network call, idempotent, and
visible in Activity as Pending until it settles.

## Entry screens
`AddMoneyPage` (`lib/features/funding/presentation/view/add_money_page.dart`), pushed from two
places: the wallet's `Add money` quick action, and Send Money's `Fund Wallet` CTA when a transfer is
blocked on insufficient funds.

## Endpoints
Nothing directly. The screen never calls `NovaPayApi.fund` itself — it enqueues, and `SyncService`
owns the call. `NovaPayApi.balance()` is read to show the balance the top-up will join.

## State
`AddMoneyCubit` — a sealed `AddMoneyState` of `initial` · `editing(draft, {error})` ·
`submitting(draft)` · `done(draft)`. Not paginated. Mirrors `ContributeCubit`'s shape: the union
carries the submission phase, `FundingDraft` carries the amount and the top-up limit check.

## Key files
1. `domain/entities/funding_draft.dart` — `withinLimit` (`kMaxTopUp`), `projected` (balance after).
2. `domain/repositories/funding_repository.dart` / `data/repositories/funding_repository_impl.dart`
   — enqueues `PendingActionType.fund`; no funds check, because money arriving has nothing to be
   short of.
3. `presentation/cubit/add_money_cubit.dart` — load balance, parse amount, submit.
4. `presentation/view/add_money_page.dart` — reuses `AmountDisplay`, `QuickAmountChips` and
   `SummaryCard` rather than a third copy of the amount-entry pattern.
5. `lib/server/services/funding_service.dart` — the stand-in backend side: idempotent, credits the
   account, titled `'Added to wallet'`.

## Gotchas
- **Funding is the one `PendingActionType` that is money arriving, not leaving.**
  `PendingActionType.isOutgoing` is `false` for `fund`, and `SyncService.pendingKobo()` filters on
  it — counting a queued top-up there would shrink the balance for adding to it. See
  `docs/features/wallet.md` and the README's [Two balances](../../README.md#two-balances) section.
- **`kPendingActionSchemaVersion` is 3 because `fund` was added to the enum.** A row from a build
  that predates it still decodes; a build older than the row would refuse to read it.
- **There is a device-side top-up limit (`kMaxTopUp`), not a server-side one.** It exists to catch a
  mistyped amount before it is queued, not as a compliance control.
- **`AddMoneyDone` never claims the money has landed.** Same wording pattern as Send Money and
  NovaSave's receipts: "is queued... closing the app will not lose it," not "added."
