import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/components/custom_input_field.dart';
import 'package:novapay/core/components/custom_scaffold.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/constants/app_color.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/features/savings/domain/entities/goal_draft.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';
import 'package:novapay/features/savings/presentation/cubit/edit_goal_cubit.dart';
import 'package:novapay/features/savings/presentation/widgets/savings_widgets.dart';

class EditGoalPage extends StatelessWidget {
  const new({required this.goal, super.key});

  final SavingsGoalItem goal;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<EditGoalCubit>();
        unawaited(cubit.start(goal));
        return cubit;
      },
      child: const EditGoalView(),
    );
  }
}

class EditGoalView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<EditGoalCubit, EditGoalState>(
      listenWhen: (previous, current) => current is EditGoalDone,
      listener: (context, state) => context.pop(),
      child: BlocBuilder<EditGoalCubit, EditGoalState>(
        builder: (context, state) {
          final draft = state.draft;
          if (draft == null) {
            return const CustomScaffold(
              title: 'Edit goal',
              body: LoadingIndicator(),
            );
          }
          return _Form(state: state, draft: draft);
        },
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.state, required this.draft});

  final EditGoalState state;
  final GoalDraft draft;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.draft.name,
  );
  late final TextEditingController _targetController = TextEditingController(
    text: widget.draft.target.toEditableString(),
  );

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditGoalCubit>();
    final draft = widget.draft;
    final state = widget.state;
    final error = state is EditGoalEditing ? state.error : null;

    return CustomScaffold(
      title: 'Edit goal',
      bottomBar: CustomButton(
        label: 'Save changes',
        isLoading: state.isSubmitting,
        onPressed: draft.canSubmit ? cubit.submit : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: AppSize.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomInputField(
              label: 'What are you saving for?',
              hint: 'Rent, school fees, a trip',
              controller: _nameController,
              autofocus: true,
              onChanged: cubit.nameChanged,
            ),
            AppSize.h(AppSize.mdl),
            CustomInputField(
              label: 'Target amount',
              hint: '0.00',
              controller: _targetController,
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
          ],
        ),
      ),
    );
  }
}
