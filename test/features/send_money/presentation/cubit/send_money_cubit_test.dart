import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_draft.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_receipt.dart';
import 'package:novapay/features/send_money/domain/usecases/load_available.dart';
import 'package:novapay/features/send_money/domain/usecases/queue_transfer.dart';
import 'package:novapay/features/send_money/presentation/cubit/send_money_cubit.dart';

class _MockLoadAvailable extends Mock implements LoadAvailable;

class _MockQueueTransfer extends Mock implements QueueTransfer;

const _available = Money.fromKobo(2000000);

const _receipt = TransferReceipt(
  reference: 'r1',
  recipient: '0123456789',
  amount: Money.fromKobo(500000),
  settled: true,
);

void main() {
  late _MockLoadAvailable loadAvailable;
  late _MockQueueTransfer queueTransfer;

  setUpAll(() {
    registerFallbackValue(
      const TransferParams(recipient: '', amount: Money.zero),
    );
  });

  setUp(() {
    loadAvailable = _MockLoadAvailable();
    queueTransfer = _MockQueueTransfer();
    when(() => loadAvailable(const NoParams()))
        .thenAnswer((_) async => const Right(_available));
    when(() => queueTransfer(any()))
        .thenAnswer((_) async => const Right(_receipt));
  });

  SendMoneyCubit build() => SendMoneyCubit(loadAvailable, queueTransfer);

  Future<SendMoneyCubit> atConfirm() async {
    final cubit = build();
    await cubit.start();
    cubit
      ..recipientChanged('0123456789')
      ..next()
      ..amountChanged('5000')
      ..next();
    return cubit;
  }

  test('opens on an empty draft at the first step', () {
    expect(build().state, const SendMoneyState.editing(TransferDraft()));
  });

  test('start brings in what may be spent', () async {
    final cubit = build();

    await cubit.start();

    expect(cubit.state.draft.available, _available);
  });

  test('a failed balance read is shown but does not block typing', () async {
    when(() => loadAvailable(const NoParams()))
        .thenAnswer((_) async => const Left(Failure.noInternet()));
    final cubit = build();

    await cubit.start();

    expect(
      cubit.state,
      isA<SendMoneyEditing>().having(
        (s) => s.error,
        'error',
        'Please check your internet connection and try again',
      ),
    );
  });

  test('a recipient is trimmed on the way in', () async {
    final cubit = build()..recipientChanged('  0123456789  ');

    expect(cubit.state.draft.recipient, '0123456789');
    expect(cubit.state.draft.recipientIsValid, isTrue);
  });

  test('an amount is parsed through Money, never a double', () async {
    final cubit = build()..amountChanged('0.29');

    expect(cubit.state.draft.amount, const Money.fromKobo(29));
  });

  test('unparseable input falls back to zero rather than throwing', () {
    final cubit = build()..amountChanged('abc');

    expect(cubit.state.draft.amount, Money.zero);
  });

  test('next refuses to advance on an invalid step', () {
    final cubit = build()
      ..recipientChanged('12345')
      ..next();

    expect(cubit.state.draft.step, SendStep.recipient);
  });

  test('next walks forward and stops at confirm', () async {
    final cubit = await atConfirm();

    expect(cubit.state.draft.step, SendStep.confirm);
    cubit.next();
    expect(cubit.state.draft.step, SendStep.confirm);
  });

  test('back walks the steps down and stops at the first', () async {
    final cubit = await atConfirm();

    cubit.back();
    expect(cubit.state.draft.step, SendStep.amount);

    cubit.back();
    expect(cubit.state.draft.step, SendStep.recipient);

    cubit.back();
    expect(cubit.state.draft.step, SendStep.recipient);
  });

  test('submit shows progress, then the receipt', () async {
    final cubit = await atConfirm();
    final seen = <SendMoneyState>[];
    final subscription = cubit.stream.listen(seen.add);

    await cubit.submit();

    expect(seen.first, isA<SendMoneySubmitting>());
    expect(cubit.state, isA<SendMoneyDone>());
    expect((cubit.state as SendMoneyDone).receipt, _receipt);
    await subscription.cancel();
  });

  test('submit sends the amount and recipient that were entered', () async {
    final cubit = await atConfirm();

    await cubit.submit();

    verify(
      () => queueTransfer(
        const TransferParams(
          recipient: '0123456789',
          amount: Money.fromKobo(500000),
        ),
      ),
    ).called(1);
  });

  test('a refusal returns to editing with copy, keeping the draft', () async {
    when(() => queueTransfer(any())).thenAnswer(
      (_) async => const Left(Failure.serverError('Not enough in your wallet')),
    );
    final cubit = await atConfirm();

    await cubit.submit();

    expect(
      cubit.state,
      isA<SendMoneyEditing>().having(
        (s) => s.error,
        'error',
        'Not enough in your wallet',
      ),
    );
    expect(cubit.state.draft.recipient, '0123456789');
    expect(cubit.state.draft.step, SendStep.confirm);
  });

  test('submit does nothing when the draft cannot be sent', () async {
    final cubit = build();

    await cubit.submit();

    expect(cubit.state, isA<SendMoneyEditing>());
    verifyNever(() => queueTransfer(any()));
  });

  test('isSubmitting is only true while in flight', () async {
    final cubit = await atConfirm();

    expect(cubit.state.isSubmitting, isFalse);
    await cubit.submit();
    expect(cubit.state.isSubmitting, isFalse);
  });
}
