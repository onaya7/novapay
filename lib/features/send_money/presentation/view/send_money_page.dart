import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/app/routes/routes_name.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/components/custom_scaffold.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_draft.dart';
import 'package:novapay/features/send_money/presentation/cubit/send_money_cubit.dart';
import 'package:novapay/features/send_money/presentation/widgets/send_money_widgets.dart';
import 'package:novapay/l10n/l10n.dart';

class SendMoneyPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<SendMoneyCubit>();
        unawaited(cubit.start());
        return cubit;
      },
      child: const SendMoneyView(),
    );
  }
}

class SendMoneyView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SendMoneyCubit, SendMoneyState>(
      builder: (context, state) {
        if (state is SendMoneyDone) {
          return _DoneScaffold(state: state);
        }
        return _StepScaffold(
          state: state,
          title: _titleFor(context, state.draft.step),
        );
      },
    );
  }

  String _titleFor(BuildContext context, SendStep step) {
    final l10n = context.l10n;
    return switch (step) {
      SendStep.recipient => l10n.sendMoneyRecipientStepTitle,
      SendStep.amount => l10n.sendMoneyAmountStepTitle,
      SendStep.confirm => l10n.sendMoneyConfirmStepTitle,
    };
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.state, required this.title});

  final SendMoneyState state;
  final String title;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SendMoneyCubit>();
    final draft = state.draft;

    return PopScope(
      canPop: draft.previousStep == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) cubit.back();
      },
      child: CustomScaffold(
        title: title,
        onBackPressed: () {
          if (draft.previousStep == null) {
            context.pop();
          } else {
            cubit.back();
          }
        },
        bottomBar: _StepCta(state: state),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(top: AppSize.lg),
          child: switch (draft.step) {
            SendStep.recipient => RecipientStep(
              draft: draft,
              banks: state.banks,
              onBankChanged: cubit.bankChanged,
              onChanged: cubit.recipientChanged,
            ),
            SendStep.amount => AmountStep(
              draft: draft,
              onChanged: cubit.amountChanged,
            ),
            SendStep.confirm => ConfirmStep(draft: draft),
          },
        ),
      ),
    );
  }
}

class _StepCta extends StatelessWidget {
  const _StepCta({required this.state});

  final SendMoneyState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SendMoneyCubit>();
    final draft = state.draft;

    final l10n = context.l10n;

    if (draft.step == SendStep.amount &&
        draft.amountIsEntered &&
        !draft.hasEnough) {
      return CustomButton(
        label: l10n.fundWalletButton,
        onPressed: () => _openAddMoney(context),
      );
    }

    if (draft.step == SendStep.confirm) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomButton(
            label: l10n.sendAmountButton(draft.amount.format()),
            isLoading: state.isSubmitting,
            onPressed: draft.canAdvance
                ? () => _confirm(context, cubit, draft)
                : null,
          ),
          AppSize.h(AppSize.xs),
          CustomButton(
            label: l10n.cancelButton,
            variant: ButtonVariant.text,
            onPressed: state.isSubmitting ? null : () => context.pop(),
          ),
        ],
      );
    }

    return CustomButton(
      label: l10n.continueButton,
      onPressed: draft.canAdvance ? cubit.next : null,
    );
  }

  void _openAddMoney(BuildContext context) {
    unawaited(context.pushNamed(RoutesName.addMoney));
  }

  /// Above the threshold, a stub biometric prompt sits between confirm and
  /// submit; `submit()` itself is unaware the prompt ever happened.
  void _confirm(
    BuildContext context,
    SendMoneyCubit cubit,
    TransferDraft draft,
  ) {
    if (draft.requiresBiometricConfirmation) {
      unawaited(context.pushNamed(RoutesName.biometricConfirm, extra: cubit));
      return;
    }
    unawaited(cubit.submit());
  }
}

class _DoneScaffold extends StatelessWidget {
  const _DoneScaffold({required this.state});

  final SendMoneyDone state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CustomScaffold(
      showBackButton: false,
      title: state.receipt.isPending ? l10n.queuedTitle : l10n.sentTitle,
      bottomBar: CustomButton(
        label: l10n.backToWalletButton,
        onPressed: () => context.pop(),
      ),
      body: SingleChildScrollView(child: ReceiptStep(receipt: state.receipt)),
    );
  }
}
