import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/components/custom_scaffold.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/features/funding/presentation/view/add_money_page.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_draft.dart';
import 'package:novapay/features/send_money/presentation/cubit/send_money_cubit.dart';
import 'package:novapay/features/send_money/presentation/widgets/send_money_widgets.dart';

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

  static const Map<SendStep, String> _titles = {
    SendStep.recipient: 'Send to',
    SendStep.amount: 'How much?',
    SendStep.confirm: 'Confirm',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SendMoneyCubit, SendMoneyState>(
      builder: (context, state) {
        if (state is SendMoneyDone) {
          return _DoneScaffold(state: state);
        }
        return _StepScaffold(state: state, title: _titles[state.draft.step]!);
      },
    );
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
            Navigator.of(context).pop();
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

    if (draft.step == SendStep.amount &&
        draft.amountIsEntered &&
        !draft.hasEnough) {
      return CustomButton(
        label: 'Fund Wallet',
        onPressed: () => _openAddMoney(context),
      );
    }

    if (draft.step == SendStep.confirm) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomButton(
            label: 'Send ${draft.amount.format()}',
            isLoading: state.isSubmitting,
            onPressed: draft.canAdvance ? cubit.submit : null,
          ),
          AppSize.h(AppSize.xs),
          CustomButton(
            label: 'Cancel',
            variant: ButtonVariant.text,
            onPressed: state.isSubmitting
                ? null
                : () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    return CustomButton(
      label: 'Continue',
      onPressed: draft.canAdvance ? cubit.next : null,
    );
  }

  void _openAddMoney(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const AddMoneyPage()));
  }
}

class _DoneScaffold extends StatelessWidget {
  const _DoneScaffold({required this.state});

  final SendMoneyDone state;

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showBackButton: false,
      title: state.receipt.isPending ? 'Queued' : 'Sent',
      bottomBar: CustomButton(
        label: 'Back to wallet',
        onPressed: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(child: ReceiptStep(receipt: state.receipt)),
    );
  }
}
