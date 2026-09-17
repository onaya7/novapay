import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/amount_display.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/components/custom_input_field.dart';
import 'package:novapay/core/components/custom_scaffold.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/components/summary_card.dart';
import 'package:novapay/core/constants/app_color.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/features/savings/domain/entities/contribution_draft.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';
import 'package:novapay/features/savings/presentation/cubit/contribute_cubit.dart';
import 'package:novapay/features/savings/presentation/widgets/savings_widgets.dart';
import 'package:novapay/l10n/l10n.dart';

class ContributePage extends StatelessWidget {
  const new({required this.goal, super.key});

  final SavingsGoalItem goal;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<ContributeCubit>();
        unawaited(cubit.start(goal));
        return cubit;
      },
      child: const ContributeView(),
    );
  }
}

class ContributeView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContributeCubit, ContributeState>(
      builder: (context, state) {
        final draft = state.draft;
        if (draft == null) {
          return CustomScaffold(
            title: context.l10n.addToGoalLabel,
            body: const LoadingIndicator(),
          );
        }
        if (state is ContributeDone) return _Done(draft: draft);
        return _Form(state: state, draft: draft);
      },
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.state, required this.draft});

  final ContributeState state;
  final ContributionDraft draft;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _choose(Money amount) {
    final text = amount.toEditableString();
    _controller
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    context.read<ContributeCubit>().amountChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ContributeCubit>();
    final draft = widget.draft;
    final state = widget.state;
    final error = state is ContributeEditing ? state.error : null;
    final l10n = context.l10n;
    final presets = <Money>[
      const Money.fromKobo(100000),
      const Money.fromKobo(500000),
      if (draft.available.kobo > 0) draft.available,
    ];

    return CustomScaffold(
      title: l10n.addToGoalLabel,
      bottomBar: CustomButton(
        label: draft.amountIsEntered
            ? l10n.addAmountButton(draft.amount.format())
            : l10n.addToGoalLabel,
        isLoading: state.isSubmitting,
        onPressed: draft.canSubmit ? cubit.submit : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: AppSize.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GoalSummaryHeader(goal: draft.goal),
            AppSize.h(AppSize.xl),
            AmountDisplay(
              amount: draft.amount,
              label: l10n.addingLabel,
              helper: _helper(context, draft),
              hasError: draft.amountIsEntered && !draft.hasEnough,
            ),
            AppSize.h(AppSize.lg),
            CustomInputField(
              label: l10n.amountLabel,
              hint: '0.00',
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [AmountInputFormatter()],
              prefix: Padding(
                padding: const EdgeInsets.only(
                  left: AppSize.md,
                  right: AppSize.sm,
                ),
                child: Text('₦', style: Theme.of(context).textTheme.bodyLarge),
              ),
              autofocus: true,
              onChanged: cubit.amountChanged,
            ),
            AppSize.h(AppSize.md),
            QuickAmountChips(
              amounts: presets,
              selected: draft.amountIsEntered ? draft.amount : null,
              onSelected: _choose,
            ),
            if (error != null) ...[
              AppSize.h(AppSize.md),
              Text(
                error,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColor.danger),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _helper(BuildContext context, ContributionDraft draft) {
    final l10n = context.l10n;
    if (!draft.amountIsEntered) return l10n.enterAmountToAddHelper;
    if (!draft.hasEnough) return l10n.notEnoughAvailableHelper;
    return l10n.amountLeftInWalletHelper(draft.remaining.format());
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.draft});

  final ContributionDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return CustomScaffold(
      title: l10n.queuedTitle,
      showBackButton: false,
      bottomBar: CustomButton(
        label: l10n.backToGoalsButton,
        onPressed: () => context.pop(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSize.h(AppSize.xxl),
            Center(
              child: Container(
                height: 88,
                width: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.successSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  size: AppSize.xl,
                  color: AppColor.success,
                ),
              ),
            ),
            AppSize.h(AppSize.lg),
            Text(
              l10n.onItsWayHeadline,
              style: texts.headlineMedium,
              textAlign: TextAlign.center,
            ),
            AppSize.h(AppSize.sm),
            Text(
              // It is queued, not settled, so this never claims it has landed.
              l10n.queuedForGoalMessage(draft.amount.format(), draft.goal.name),
              textAlign: TextAlign.center,
              style: texts.bodyMedium?.copyWith(color: colors.textSubheading),
            ),
            AppSize.h(AppSize.lg),
            SummaryCard(
              children: [
                SummaryRow(label: l10n.goalRowLabel, value: draft.goal.name),
                SummaryRow(
                  label: l10n.amountLabel,
                  value: draft.amount.format(),
                  emphasised: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
