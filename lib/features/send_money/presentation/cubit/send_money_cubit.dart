import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_draft.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_receipt.dart';
import 'package:novapay/features/send_money/domain/usecases/load_available.dart';
import 'package:novapay/features/send_money/domain/usecases/queue_transfer.dart';

part 'send_money_cubit.freezed.dart';
part 'send_money_state.dart';

@injectable
class SendMoneyCubit extends Cubit<SendMoneyState> {
  SendMoneyCubit(this._loadAvailable, this._queueTransfer)
    : super(const SendMoneyState.editing(TransferDraft()));

  final LoadAvailable _loadAvailable;
  final QueueTransfer _queueTransfer;

  static const ConvertFailureToString _toMessage = ConvertFailureToString();

  TransferDraft get _draft => state.draft;

  Future<void> start() async {
    final result = await _loadAvailable(const NoParams());
    emit(
      result.fold(
        (failure) => SendMoneyState.editing(_draft, error: _toMessage(failure)),
        (available) =>
            SendMoneyState.editing(_draft.copyWith(available: available)),
      ),
    );
  }

  void recipientChanged(String value) {
    emit(SendMoneyState.editing(_draft.copyWith(recipient: value.trim())));
  }

  /// Parses through [Money], so a typed amount never becomes a double.
  void amountChanged(String value) {
    emit(
      SendMoneyState.editing(
        _draft.copyWith(amount: Money.tryParse(value) ?? Money.zero),
      ),
    );
  }

  void next() {
    final step = _draft.nextStep;
    if (step == null || !_draft.canAdvance) return;
    emit(SendMoneyState.editing(_draft.copyWith(step: step)));
  }

  void back() {
    final step = _draft.previousStep;
    if (step == null) return;
    emit(SendMoneyState.editing(_draft.copyWith(step: step)));
  }

  Future<void> submit() async {
    if (!_draft.canAdvance) return;
    final draft = _draft;
    emit(SendMoneyState.submitting(draft));

    final result = await _queueTransfer(
      TransferParams(recipient: draft.recipient, amount: draft.amount),
    );

    emit(
      result.fold(
        (failure) => SendMoneyState.editing(draft, error: _toMessage(failure)),
        (receipt) => SendMoneyState.done(draft, receipt),
      ),
    );
  }
}
