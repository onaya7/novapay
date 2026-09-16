import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/funding/domain/usecases/funding_usecases.dart';
import 'package:novapay/features/funding/presentation/cubit/add_money_cubit.dart';

class _MockLoadWalletBalance extends Mock implements LoadWalletBalance;

class _MockAddMoney extends Mock implements AddMoney;

const _balance = Money.fromKobo(2000000);

void main() {
  late _MockLoadWalletBalance loadBalance;
  late _MockAddMoney addMoney;

  setUpAll(() => registerFallbackValue(Money.zero));

  setUp(() {
    loadBalance = _MockLoadWalletBalance();
    addMoney = _MockAddMoney();
    when(() => loadBalance(const NoParams()))
        .thenAnswer((_) async => const Right(_balance));
    when(() => addMoney(any())).thenAnswer((_) async => const Right(unit));
  });

  AddMoneyCubit build() => AddMoneyCubit(loadBalance, addMoney);

  Future<AddMoneyCubit> started() async {
    final cubit = build();
    await cubit.start();
    return cubit;
  }

  test('it has no draft until the balance has loaded', () {
    expect(build().state.draft, isNull);
  });

  test('start brings in the wallet balance', () async {
    final cubit = await started();

    expect(cubit.state.draft?.balance, _balance);
  });

  test('a failed balance read is shown but does not block typing', () async {
    when(() => loadBalance(const NoParams()))
        .thenAnswer((_) async => const Left(Failure.noInternet()));
    final cubit = build();

    await cubit.start();

    expect(
      cubit.state,
      isA<AddMoneyEditing>().having(
        (s) => s.error,
        'error',
        'Please check your internet connection and try again',
      ),
    );
    expect(cubit.state.draft?.balance, Money.zero);
  });

  test('an amount is parsed through Money', () async {
    final cubit = await started();

    cubit.amountChanged('0.29');

    expect(cubit.state.draft?.amount, const Money.fromKobo(29));
  });

  test('typing before the balance lands is ignored, not a crash', () {
    final cubit = build()..amountChanged('500');

    expect(cubit.state.draft, isNull);
  });

  test('submit queues the top-up and finishes', () async {
    final cubit = await started();
    cubit.amountChanged('5000');

    await cubit.submit();

    expect(cubit.state, isA<AddMoneyDone>());
    verify(() => addMoney(const Money.fromKobo(500000))).called(1);
  });

  test('submit does nothing over the top-up limit', () async {
    final cubit = await started();
    cubit.amountChanged('600000');

    await cubit.submit();

    expect(cubit.state, isA<AddMoneyEditing>());
    expect(cubit.state.draft?.withinLimit, isFalse);
    verifyNever(() => addMoney(any()));
  });

  test('submit before the balance lands does nothing', () async {
    final cubit = build();

    await cubit.submit();

    expect(cubit.state, isA<AddMoneyInitial>());
    verifyNever(() => addMoney(any()));
  });

  test('a refusal returns to editing with copy', () async {
    when(() => addMoney(any()))
        .thenAnswer((_) async => const Left(Failure.serverError('Not enough')));
    final cubit = await started();
    cubit.amountChanged('5000');

    await cubit.submit();

    expect(
      cubit.state,
      isA<AddMoneyEditing>().having((s) => s.error, 'error', 'Not enough'),
    );
  });

  test('isSubmitting is only true while in flight', () async {
    final cubit = await started();
    cubit.amountChanged('5000');
    final seen = <AddMoneyState>[];
    final subscription = cubit.stream.listen(seen.add);

    await cubit.submit();

    expect(seen.first, isA<AddMoneySubmitting>());
    expect(cubit.state.isSubmitting, isFalse);
    await subscription.cancel();
  });
}
