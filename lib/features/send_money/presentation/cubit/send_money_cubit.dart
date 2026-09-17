import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/send_money/domain/entities/bank.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_draft.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_receipt.dart';
import 'package:novapay/features/send_money/domain/usecases/load_available.dart';
import 'package:novapay/features/send_money/domain/usecases/load_banks.dart';
import 'package:novapay/features/send_money/domain/usecases/queue_transfer.dart';

part 'send_money_cubit.freezed.dart';
part 'send_money_state.dart';

@injectable
class SendMoneyCubit extends Cubit<SendMoneyState> {
  SendMoneyCubit(this._loadAvailable, this._loadBanks, this._queueTransfer)
    : super(const SendMoneyState.editing(TransferDraft()));

  final LoadAvailable _loadAvailable;
  final LoadBanks _loadBanks;
  final QueueTransfer _queueTransfer;

  static const ConvertFailureToString _toMessage = ConvertFailureToString();

  TransferDraft get _draft => state.draft;

  Future<void> start() async {
    final available = await _loadAvailable(const NoParams());
    final banks = await _loadBanks(const NoParams());
    emit(
      available.fold(
        (failure) => SendMoneyState.editing(
          _draft,
          banks: banks.getOrElse(() => const []),
          error: _toMessage(failure),
        ),
        (amount) => SendMoneyState.editing(
          _draft.copyWith(available: amount),
          banks: banks.getOrElse(() => const []),
        ),
      ),
    );
  }

  void bankChanged(Bank bank) {
    emit(
      SendMoneyState.editing(_draft.copyWith(bank: bank), banks: state.banks),
    );
  }

  void recipientChanged(String value) {
    emit(
      SendMoneyState.editing(
        _draft.copyWith(recipient: value.trim()),
        banks: state.banks,
      ),
    );
  }

  /// Parses through [Money], so a typed amount never becomes a double.
  void amountChanged(String value) {
    emit(
      SendMoneyState.editing(
        _draft.copyWith(amount: Money.tryParse(value) ?? Money.zero),
        banks: state.banks,
      ),
    );
  }

  void next() {
    final step = _draft.nextStep;
    if (step == null || !_draft.canAdvance) return;
    emit(
      SendMoneyState.editing(_draft.copyWith(step: step), banks: state.banks),
    );
  }

  void back() {
    final step = _draft.previousStep;
    if (step == null) return;
    emit(
      SendMoneyState.editing(_draft.copyWith(step: step), banks: state.banks),
    );
  }

  Future<void> submit() async {
    if (!_draft.canAdvance) return;
    final draft = _draft;
    final bank = draft.bank;
    if (bank == null) return;
    emit(SendMoneyState.submitting(draft));

    final result = await _queueTransfer(
      TransferParams(
        bankCode: bank.code,
        bankName: bank.name,
        recipient: draft.recipient,
        amount: draft.amount,
      ),
    );

    emit(
      result.fold(
        (failure) => SendMoneyState.editing(
          draft,
          banks: state.banks,
          error: _toMessage(failure),
        ),
        (receipt) => SendMoneyState.done(draft, receipt),
      ),
    );
  }
}
