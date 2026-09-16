import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:novapay/features/funding/domain/entities/funding_draft.dart';
import 'package:novapay/features/funding/presentation/cubit/add_money_cubit.dart';

class AddMoneyPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<AddMoneyCubit>();
        unawaited(cubit.start());
        return cubit;
      },
      child: const AddMoneyView(),
    );
  }
}

class AddMoneyView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddMoneyCubit, AddMoneyState>(
      builder: (context, state) {
        final draft = state.draft;
        if (draft == null) {
          return const CustomScaffold(
            title: 'Add money',
            body: LoadingIndicator(),
          );
        }
        if (state is AddMoneyDone) return _Done(draft: draft);
        return _Form(state: state, draft: draft);
      },
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.state, required this.draft});

  final AddMoneyState state;
  final FundingDraft draft;

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
    final text = amount.format(withSymbol: false);
    _controller
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    context.read<AddMoneyCubit>().amountChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddMoneyCubit>();
    final draft = widget.draft;
    final state = widget.state;
    final error = state is AddMoneyEditing ? state.error : null;

    return CustomScaffold(
      title: 'Add money',
      bottomBar: CustomButton(
        label: draft.amountIsEntered
            ? 'Add ${draft.amount.format()}'
            : 'Add money',
        isLoading: state.isSubmitting,
        onPressed: draft.canSubmit ? cubit.submit : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: AppSize.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AmountDisplay(
              amount: draft.amount,
              label: 'Adding',
              helper: _helper(draft),
              hasError: draft.amountIsEntered && !draft.withinLimit,
            ),
            AppSize.h(AppSize.lg),
            CustomInputField(
              label: 'Amount',
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
              amounts: const [
                Money.fromKobo(500000),
                Money.fromKobo(2000000),
                Money.fromKobo(5000000),
              ],
              selected: draft.amountIsEntered ? draft.amount : null,
              onSelected: _choose,
            ),
            AppSize.h(AppSize.lg),
            SummaryCard(
              children: [
                SummaryRow(
                  label: 'Wallet balance',
                  value: draft.balance.format(),
                ),
                SummaryRow(
                  label: 'After this top-up',
                  value: draft.projected.format(),
                  emphasised: true,
                ),
              ],
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

  String _helper(FundingDraft draft) {
    if (!draft.amountIsEntered) return 'Enter how much to add';
    if (!draft.withinLimit) {
      return 'One top-up cannot be more than ${kMaxTopUp.format()}';
    }
    return 'Your balance becomes ${draft.projected.format()}';
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.draft});

  final FundingDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;

    return CustomScaffold(
      title: 'Queued',
      showBackButton: false,
      bottomBar: CustomButton(
        label: 'Back to wallet',
        onPressed: () => Navigator.of(context).pop(),
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
                  Icons.add_card_outlined,
                  size: AppSize.xl,
                  color: AppColor.success,
                ),
              ),
            ),
            AppSize.h(AppSize.lg),
            Text(
              'On its way',
              style: texts.headlineMedium,
              textAlign: TextAlign.center,
            ),
            AppSize.h(AppSize.sm),
            Text(
              '${draft.amount.format()} is queued for your wallet. '
              'It is saved, so closing the app will not lose it.',
              textAlign: TextAlign.center,
              style: texts.bodyMedium?.copyWith(color: colors.textSubheading),
            ),
            AppSize.h(AppSize.lg),
            SummaryCard(
              children: [
                SummaryRow(
                  label: 'Amount',
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
