import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/usecase/usecase.dart';
import 'package:novapay/features/funding/domain/entities/funding_draft.dart';
import 'package:novapay/features/funding/domain/usecases/funding_usecases.dart';

part 'add_money_cubit.freezed.dart';
part 'add_money_state.dart';

@injectable
class AddMoneyCubit extends Cubit<AddMoneyState> {
  AddMoneyCubit(this._loadBalance, this._addMoney)
    : super(const AddMoneyState.initial());

  final LoadWalletBalance _loadBalance;
  final AddMoney _addMoney;

  static const ConvertFailureToString _toMessage = ConvertFailureToString();

  Future<void> start() async {
    final result = await _loadBalance(const NoParams());
    emit(
      result.fold(
        (failure) => AddMoneyState.editing(
          const FundingDraft(),
          error: _toMessage(failure),
        ),
        (balance) => AddMoneyState.editing(FundingDraft(balance: balance)),
      ),
    );
  }

  /// Parses through [Money], so a typed amount never becomes a double.
  void amountChanged(String value) {
    final draft = state.draft;
    if (draft == null) return;
    emit(
      AddMoneyState.editing(
        draft.copyWith(amount: Money.tryParse(value) ?? Money.zero),
      ),
    );
  }

  Future<void> submit() async {
    final draft = state.draft;
    if (draft == null || !draft.canSubmit) return;
    emit(AddMoneyState.submitting(draft));

    final result = await _addMoney(draft.amount);

    emit(
      result.fold(
        (failure) => AddMoneyState.editing(draft, error: _toMessage(failure)),
        (_) => AddMoneyState.done(draft),
      ),
    );
  }
}
