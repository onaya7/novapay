# Send money

## Purpose
Move money to a bank account in three steps, writing the transfer to the local queue before any
network call so it survives being offline or force-quit. The recipient step asks for a real bank
before the account number, the way an actual NUBAN transfer does.

## Entry screens
`SendMoneyPage` (`lib/features/send_money/presentation/view/send_money_page.dart`), pushed as a
`taskRoute` (`RoutesName.sendMoney`) from the wallet's `Send money` action. One page renders all
three steps plus the receipt; back walks the steps down and only leaves the flow from the first
one. Picking a bank opens `BankPickerSheet` as a `showModalBottomSheet`, not a fourth step.

## Endpoints
Nothing directly. The screen never calls `NovaPayApi.transfer` itself — it enqueues, and
`SyncService` owns the call. `NovaPayApi.balance()` is read to compute what is spendable. There is
no bank-list endpoint: `BankRepositoryImpl` is a local, curated, hardcoded list of real banks with
their real NIP codes.

## State
`SendMoneyCubit` — a sealed `SendMoneyState` of `editing(draft, {banks, error})` ·
`submitting(draft)` · `done(draft, receipt)`. Not paginated. The union carries the *submission*
phase and the loaded bank list; `TransferDraft` carries the form and every rule that gates it, so no
rule lives in a widget.

## Key files
1. `domain/entities/bank.dart` / `domain/repositories/bank_repository.dart` /
   `data/repositories/bank_repository_impl.dart` — the curated bank list and its real NIP codes.
2. `domain/entities/transfer_draft.dart` — the steps, the validation (now including a chosen bank),
   `hasEnough`, and `requiresBiometricConfirmation`.
3. `data/repositories/transfer_repository_impl.dart` — the funds guard and the enqueue.
4. `presentation/cubit/send_money_cubit.dart` — step navigation, bank selection and submit.
5. `presentation/widgets/send_money_widgets.dart` — the three steps and the receipt, every string
   routed through `context.l10n` (`lib/l10n/arb/`; English, Spanish and French).
6. `presentation/widgets/bank_picker_sheet.dart` / `bank_avatar.dart` — the searchable picker and
   the logo-or-initials avatar it shares with the recipient step.
7. `presentation/view/biometric_confirm_page.dart` — the biometric confirmation screen, pushed as
   `RoutesName.biometricConfirm` when `requiresBiometricConfirmation` is true.
8. `core/auth/biometric_authenticator.dart` — `BiometricAuthenticator`, backed by `local_auth`.

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
- **A bank is required, not just an account number.** `TransferDraft.recipientIsValid` needs both —
  the CTA stays dead on a valid ten-digit number alone, until a bank is also chosen.
- **The bank list is bundled locally, not fetched.** `BankRepositoryImpl` returns a curated ~10-bank
  list with real logos shipped as tracked assets (`assets/images/banks/`), reached only through
  `flutter_gen` (`Assets.images.banks.*`). This keeps the picker fully offline, consistent with the
  rest of this app, rather than depending on a live third-party logo API.
- **The bank and account number both flow into the queue's payload and the settled title.**
  `SyncService`'s `payload` map is free-form, so `bankCode`/`bankName` ride alongside `recipient`
  with no `kPendingActionSchemaVersion` bump. `WalletRepositoryImpl` and the server's
  `TransferServiceImpl` both fall back to the pre-bank title format for older rows that never
  carried one.
- **Above `kBiometricConfirmThresholdKobo` (₦50,000), the confirm CTA pushes `BiometricConfirmPage`**
  instead of calling `cubit.submit()` directly. The page calls `BiometricAuthenticator.authenticate()`
  (`local_auth` underneath: Face ID/fingerprint, falling back to device PIN/pattern per
  `isDeviceSupported()`) and only calls `submit()` — then pops — when it returns `true`. A cancelled,
  refused or unenrolled prompt resets the button and leaves the confirm step exactly where it was.
- **`BiometricAuthenticator` is resolved through `sl<BiometricAuthenticator>()`**, the same DI
  convention as every other cross-cutting service (`register_module.dart` provides the underlying
  `LocalAuthentication`); `BiometricConfirmPage`'s constructor also takes an optional override, which
  is how tests substitute a mock without touching the container.
- **`BiometricConfirmPage` is handed the live `SendMoneyCubit`, not a copy.** The route reads it
  back from `state.extra` and wraps it in `BlocProvider.value`, so the page acts on the same draft
  the confirm step was already holding — there is no second cubit to keep in sync.
- **A queued send fires exactly one local notification when it settles**, from
  `lib/core/notifications/transfer_sync_notifier.dart`, which diffs `SyncService.changes` rather
  than living inside `SyncServiceImpl` — the queue itself stays Flutter-plugin-free. Contributions
  and top-ups are deliberately silent; only `PendingActionType.send` triggers it.
