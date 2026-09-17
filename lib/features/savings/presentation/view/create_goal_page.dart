import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/components/custom_input_field.dart';
import 'package:novapay/core/components/custom_scaffold.dart';
import 'package:novapay/core/constants/app_color.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/features/savings/presentation/cubit/create_goal_cubit.dart';
import 'package:novapay/features/savings/presentation/widgets/savings_widgets.dart';
import 'package:novapay/l10n/l10n.dart';

class CreateGoalPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CreateGoalCubit>(),
      child: const CreateGoalView(),
    );
  }
}

class CreateGoalView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateGoalCubit, CreateGoalState>(
      listenWhen: (previous, current) => current is CreateGoalDone,
      listener: (context, state) => context.pop(),
      child: BlocBuilder<CreateGoalCubit, CreateGoalState>(
        builder: (context, state) {
          final cubit = context.read<CreateGoalCubit>();
          final draft = state.draft;
          final error = state is CreateGoalEditing ? state.error : null;
          final l10n = context.l10n;

          return CustomScaffold(
            title: l10n.newGoalTitle,
            bottomBar: CustomButton(
              label: l10n.createGoalButton,
              isLoading: state.isSubmitting,
              onPressed: draft.canSubmit ? cubit.submit : null,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.only(top: AppSize.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomInputField(
                    label: l10n.goalNameLabel,
                    hint: l10n.goalNameHint,
                    autofocus: true,
                    onChanged: cubit.nameChanged,
                  ),
                  AppSize.h(AppSize.mdl),
                  CustomInputField(
                    label: l10n.targetAmountLabel,
                    hint: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [AmountInputFormatter()],
                    prefix: Padding(
                      padding: const EdgeInsets.only(
                        left: AppSize.md,
                        right: AppSize.sm,
                      ),
                      child: Text(
                        '₦',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    onChanged: cubit.targetChanged,
                  ),
                  AppSize.h(AppSize.mdl),
                  GoalDateField(
                    value: draft.targetDate,
                    onChanged: cubit.dateChanged,
                  ),
                  if (error != null) ...[
                    AppSize.h(AppSize.md),
                    Text(
                      error,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColor.danger),
                    ),
                  ],
                  AppSize.h(AppSize.md),
                  Text(
                    l10n.moneyMovesLaterNote,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppThemeColors.of(context).subtext),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
