import 'package:injectable/injectable.dart';
import 'package:novapay/features/send_money/domain/entities/bank.dart';
import 'package:novapay/features/send_money/domain/repositories/bank_repository.dart';
import 'package:novapay/gen/assets.gen.dart';

@LazySingleton(as: BankRepository)
class BankRepositoryImpl implements BankRepository {
  const BankRepositoryImpl();

  /// A curated set, not the full CBN list — a demo picker doesn't need every
  /// microfinance bank, and each entry here is a real bank with its real
  /// NIP code.
  static final List<Bank> _banks = [
    Bank(
      code: '058',
      name: 'Guaranty Trust Bank',
      logoAsset: Assets.images.banks.gtbank.path,
    ),
    Bank(
      code: '044',
      name: 'Access Bank',
      logoAsset: Assets.images.banks.accessBank.path,
    ),
    Bank(
      code: '057',
      name: 'Zenith Bank',
      logoAsset: Assets.images.banks.zenithBank.path,
    ),
    Bank(
      code: '033',
      name: 'United Bank for Africa',
      logoAsset: Assets.images.banks.uba.path,
    ),
    Bank(
      code: '011',
      name: 'First Bank of Nigeria',
      logoAsset: Assets.images.banks.firstBank.path,
    ),
    Bank(
      code: '50211',
      name: 'Kuda Bank',
      logoAsset: Assets.images.banks.kuda.path,
    ),
    Bank(
      code: '999992',
      name: 'OPay',
      logoAsset: Assets.images.banks.opay.path,
    ),
    Bank(
      code: '50515',
      name: 'Moniepoint MFB',
      logoAsset: Assets.images.banks.moniepoint.path,
    ),
    Bank(
      code: '070',
      name: 'Fidelity Bank',
      logoAsset: Assets.images.banks.fidelityBank.path,
    ),
    Bank(
      code: '035',
      name: 'Wema Bank',
      logoAsset: Assets.images.banks.wemaBank.path,
    ),
  ];

  @override
  List<Bank> banks() => _banks;
}
