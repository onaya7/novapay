import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/features/send_money/data/repositories/bank_repository_impl.dart';

void main() {
  test('lists a curated set of real banks, each with a code and a name', () {
    final banks = const BankRepositoryImpl().banks();

    expect(banks, isNotEmpty);
    for (final bank in banks) {
      expect(bank.code, isNotEmpty);
      expect(bank.name, isNotEmpty);
    }
    expect(banks.map((b) => b.code).toSet().length, banks.length);
  });

  test('every bundled logo resolves to a flutter_gen asset path', () {
    final banks = const BankRepositoryImpl().banks();

    for (final bank in banks) {
      expect(bank.logoAsset, startsWith('assets/images/banks/'));
    }
  });
}
