import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/features/wallet/domain/entities/activity_item.dart';

part 'wallet_snapshot.freezed.dart';

/// Everything the wallet home renders, computed in one place so the two
/// balances can never disagree.
@freezed
abstract class WalletSnapshot with _$WalletSnapshot {
  const factory WalletSnapshot({
    required int confirmedKobo,
    required int pendingKobo,
    required List<ActivityItem> activity,
  }) = _WalletSnapshot;

  const WalletSnapshot._();

  /// The server's number, never computed on the client.
  Money get confirmed => Money.fromKobo(confirmedKobo);

  Money get pending => Money.fromKobo(pendingKobo);

  /// What the customer may actually spend; committed money is already gone.
  Money get available => Money.fromKobo(confirmedKobo - pendingKobo);

  bool get hasPending => pendingKobo > 0;

  bool get hasActivity => activity.isNotEmpty;
}
