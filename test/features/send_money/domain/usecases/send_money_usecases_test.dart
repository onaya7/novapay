import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_receipt.dart';
import 'package:novapay/features/send_money/domain/repositories/transfer_repository.dart';
import 'package:novapay/features/send_money/domain/usecases/load_available.dart';
import 'package:novapay/features/send_money/domain/usecases/queue_transfer.dart';

class _MockTransferRepository extends Mock implements TransferRepository;

const _receipt = TransferReceipt(
  reference: 'r1',
  recipient: '0123456789',
  amount: Money.fromKobo(500000),
  settled: false,
);

void main() {
  late _MockTransferRepository repository;

  setUpAll(() => registerFallbackValue(Money.zero));

  setUp(() => repository = _MockTransferRepository());

  test('LoadAvailable delegates and passes the amount back', () async {
    when(repository.available)
        .thenAnswer((_) async => const Right(Money.fromKobo(100)));

    final result = await LoadAvailable(repository)(const NoParams());

    expect(result, const Right<Failure, Money>(Money.fromKobo(100)));
  });

  test('QueueTransfer hands the params through unchanged', () async {
    when(
      () => repository.queue(
        recipient: any(named: 'recipient'),
        amount: any(named: 'amount'),
      ),
    ).thenAnswer((_) async => const Right(_receipt));

    final result = await QueueTransfer(repository)(
      const TransferParams(
        recipient: '0123456789',
        amount: Money.fromKobo(500000),
      ),
    );

    expect(result, const Right<Failure, TransferReceipt>(_receipt));
    verify(
      () => repository.queue(
        recipient: '0123456789',
        amount: const Money.fromKobo(500000),
      ),
    ).called(1);
  });

  test('TransferParams is a value, so two identical ones match', () {
    const a = TransferParams(recipient: '1', amount: Money.fromKobo(2));
    const b = TransferParams(recipient: '1', amount: Money.fromKobo(2));

    expect(a, b);
    expect(a.props, ['1', const Money.fromKobo(2)]);
  });
}
