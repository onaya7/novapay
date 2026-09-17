import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/app/routes/routes_name.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/components/custom_scaffold.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/features/savings/domain/entities/savings_goal_item.dart';
import 'package:novapay/features/savings/presentation/cubit/savings_cubit.dart';
import 'package:novapay/features/savings/presentation/widgets/savings_widgets.dart';
import 'package:novapay/l10n/l10n.dart';

class SavingsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<SavingsCubit>();
        unawaited(cubit.start());
        return cubit;
      },
      child: const SavingsView(),
    );
  }
}

class SavingsView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: context.l10n.novaSaveTitle,
      padding: EdgeInsets.zero,
      bottomBar: CustomButton(
        label: context.l10n.createGoalButton,
        leading: const Icon(Icons.add, size: AppSize.iconMd),
        onPressed: () => _openCreate(context),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<SavingsCubit>().refresh(),
        child: BlocBuilder<SavingsCubit, SavingsState>(
          builder: (context, state) => switch (state) {
            SavingsLoading() => const _Loading(),
            SavingsFailure(:final message) => _Failure(message: message),
            SavingsReady(:final goals) => _Ready(goals: goals),
          },
        ),
      ),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    final cubit = context.read<SavingsCubit>();
    await context.pushNamed(RoutesName.createGoal);
    await cubit.refresh();
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const PullToRefreshBody(
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSize.md, AppSize.md, AppSize.md, 0),
        child: SavingsSkeleton(),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return PullToRefreshBody(
      alignment: Alignment.center,
      child: AppErrorState(
        message: message,
        onRetry: () => context.read<SavingsCubit>().refresh(),
      ),
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.goals});

  final List<SavingsGoalItem> goals;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return PullToRefreshBody(
        alignment: Alignment.center,
        child: AppEmptyState(
          message: context.l10n.noGoalsMessage,
          icon: Icons.savings_outlined,
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSize.md,
        AppSize.md,
        AppSize.md,
        AppSize.md,
      ),
      itemCount: goals.length,
      separatorBuilder: (context, index) => AppSize.h(AppSize.smd),
      itemBuilder: (context, index) {
        final goal = goals[index];
        return GoalCard(
          key: ValueKey(goal.id),
          goal: goal,
          onTap: () => _openContribute(context, goal),
          onMore: () => _openActions(context, goal),
        );
      },
    );
  }

  Future<void> _openContribute(
    BuildContext context,
    SavingsGoalItem goal,
  ) async {
    final cubit = context.read<SavingsCubit>();
    await context.pushNamed(RoutesName.contribute, extra: goal);
    await cubit.refresh();
  }

  Future<void> _openActions(BuildContext context, SavingsGoalItem goal) async {
    final cubit = context.read<SavingsCubit>();
    final action = await showModalBottomSheet<GoalAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSize.radiusXl),
        ),
      ),
      builder: (_) => const GoalActionsSheet(),
    );
    if (!context.mounted || action == null) return;

    switch (action) {
      case GoalAction.edit:
        await context.pushNamed(RoutesName.editGoal, extra: goal);
        await cubit.refresh();
      case GoalAction.delete:
        await _confirmDelete(context, cubit, goal);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SavingsCubit cubit,
    SavingsGoalItem goal,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSize.radiusXl),
        ),
      ),
      builder: (_) => DeleteGoalConfirmSheet(goalName: goal.name),
    );
    if (confirmed != true) return;
    await cubit.delete(goal.id);
  }
}
