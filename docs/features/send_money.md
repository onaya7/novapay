# Send money

## Purpose
Move money to a NUBAN account in three steps, writing the transfer to the local queue before any
network call so it survives being offline or force-quit.

## Entry screens
`SendMoneyPage` (`lib/features/send_money/presentation/view/send_money_page.dart`), pushed from the
wallet's `Send money` action. One page renders all three steps plus the receipt; back walks the
steps down and only leaves the flow from the first one.

## Endpoints
Nothing directly. The screen never calls `NovaPayApi.transfer` itself — it enqueues, and
`SyncService` owns the call. `NovaPayApi.balance()` is read to compute what is spendable.

## State
`SendMoneyCubit` — a sealed `SendMoneyState` of `editing(draft, {error})` · `submitting(draft)` ·
`done(draft, receipt)`. Not paginated. The union carries the *submission* phase; `TransferDraft`
carries the form and every rule that gates it, so no rule lives in a widget.

## Key files
1. `domain/entities/transfer_draft.dart` — the steps, the validation, and `hasEnough`.
2. `data/repositories/transfer_repository_impl.dart` — the funds guard and the enqueue.
3. `presentation/cubit/send_money_cubit.dart` — step navigation and submit.
4. `presentation/widgets/send_money_widgets.dart` — the three steps and the receipt.

## Gotchas
- **The amount step advances even when there is not enough.** `canAdvance` is deliberately true
  there so the CTA can become `Fund Wallet` rather than going dead. `confirm` is where `hasEnough`
  actually gates submission.
- **The funds guard exists twice, on purpose.** The screen blocks it, and
  `TransferRepositoryImpl.queue` blocks it again — the balance can move between the confirm screen
  opening and the button being pressed.
- **`SyncService.enqueue` awaits its own drain.** Do not `drain()` again after enqueuing; that
  spends two of the five attempts on one action.
- **A receipt never claims a send that was not acknowledged.** `settled` is read back from the queue
  after the drain; anything else is shown as `Queued`, which covers offline and a timeout alike.
- **`SendMoneyCubit` is a factory, not a singleton.** A second transfer must start from an empty
  draft, so it must not survive the screen.
- **`Fund Wallet` navigates to the real funding flow (`AddMoneyPage`)**, not a stub. A blocked
  screen keeps a live CTA that fixes the problem; a disabled button there would be a dead end rather
  than a state.
- **The amount step still has a real `TextField`.** The large figure is a display; the field beneath
  it is what owns the keyboard, `AmountInputFormatter` and the `Money.tryParse` path. Do not replace
  it with a custom keypad without moving that parsing with it.
- **A quick-amount chip writes through the same `onChanged` as typing**, so there is one code path
  into the draft. `AmountStep` owns the controller because a chip has to push text back into it.
