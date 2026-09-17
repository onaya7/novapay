import 'package:novapay/features/send_money/domain/entities/bank.dart';

abstract class BankRepository {
  /// The bank list a recipient can be sent to. Local and static — there is
  /// no bank-list endpoint on the stand-in server.
  List<Bank> banks();
}
