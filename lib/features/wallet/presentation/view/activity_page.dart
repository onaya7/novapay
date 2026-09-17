import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/app/routes/routes_name.dart';
import 'package:novapay/core/components/custom_scaffold.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/features/wallet/domain/entities/activity_item.dart';
import 'package:novapay/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:novapay/features/wallet/presentation/widgets/wallet_widgets.dart';
import 'package:novapay/l10n/l10n.dart';

/// The full history. It reads the same snapshot the wallet does, so a queued
/// action appears in both without a second source of truth.
class ActivityPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<WalletCubit>();
        unawaited(cubit.start());
        return cubit;
      },
      child: const ActivityView(),
    );
  }
}

class ActivityView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: context.l10n.activityLabel,
      showBackButton: false,
      padding: EdgeInsets.zero,
      body: RefreshIndicator(
        onRefresh: () => context.read<WalletCubit>().refresh(),
        child: BlocBuilder<WalletCubit, WalletState>(
          builder: (context, state) => switch (state) {
            WalletLoading() => const _Loading(),
            WalletFailure(:final message) => _Failure(message: message),
            WalletReady(:final snapshot) => _Rows(rows: snapshot.activity),
          },
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const PullToRefreshBody(
      child: Padding(
        padding: EdgeInsets.all(AppSize.md),
        child: ActivitySkeleton(),
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
        onRetry: () => context.read<WalletCubit>().refresh(),
      ),
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({required this.rows});

  final List<ActivityItem> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return PullToRefreshBody(
        alignment: Alignment.center,
        child: AppEmptyState(
          message: context.l10n.noHistoryMessage,
          icon: Icons.receipt_long,
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
      itemCount: rows.length,
      separatorBuilder: (context, index) => AppSize.h(AppSize.smd),
      itemBuilder: (context, index) {
        final item = rows[index];
        return ActivityRow(
          key: ValueKey(item.id),
          item: item,
          onTap: () => _openDetail(context, item),
        );
      },
    );
  }

  void _openDetail(BuildContext context, ActivityItem item) {
    unawaited(context.pushNamed(RoutesName.transactionDetail, extra: item));
  }
}
