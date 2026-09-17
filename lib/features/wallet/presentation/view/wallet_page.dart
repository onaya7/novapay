import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/app/routes/routes_name.dart';
import 'package:novapay/core/components/custom_scaffold.dart';
import 'package:novapay/core/components/section_header.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/core/extensions/date_time_extension.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:novapay/features/wallet/domain/entities/activity_item.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';
import 'package:novapay/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:novapay/features/wallet/presentation/widgets/wallet_widgets.dart';
import 'package:novapay/gen/assets.gen.dart';

class WalletPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<WalletCubit>();
        unawaited(cubit.start());
        return cubit;
      },
      child: const WalletView(),
    );
  }
}

class WalletView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showBackButton: false,
      padding: EdgeInsets.zero,
      body: RefreshIndicator(
        onRefresh: () => context.read<WalletCubit>().refresh(),
        child: BlocBuilder<WalletCubit, WalletState>(
          builder: (context, state) => switch (state) {
            WalletLoading() => const _Loading(),
            WalletFailure(:final message) => _Failure(message: message),
            WalletReady(:final snapshot) => _Ready(snapshot: snapshot),
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
        padding: EdgeInsets.fromLTRB(AppSize.md, AppSize.md, AppSize.md, 0),
        child: WalletSkeleton(),
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

class _Ready extends StatelessWidget {
  const _Ready({required this.snapshot});

  final WalletSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (!snapshot.hasActivity) {
      return PullToRefreshBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSize.md,
                AppSize.md,
                AppSize.md,
                0,
              ),
              child: _Header(snapshot: snapshot, showActivityLabel: false),
            ),
            AppSize.h(AppSize.lg),
            const AppEmptyState(
              message:
                  'No activity yet.\n'
                  'Money you send or save shows up here.',
              icon: Icons.receipt_long,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSize.md,
        AppSize.md,
        AppSize.md,
        AppSize.xxl,
      ),
      itemCount: snapshot.activity.length + 1,
      separatorBuilder: (context, index) => AppSize.h(AppSize.smd),
      itemBuilder: (context, index) {
        if (index == 0) return _Header(snapshot: snapshot);
        final item = snapshot.activity[index - 1];
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

class _Header extends StatelessWidget {
  const _Header({required this.snapshot, this.showActivityLabel = true});

  final WalletSnapshot snapshot;
  final bool showActivityLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WalletHeader(
          title: context.watch<ProfileCubit>().state.profile.greetingName,
          greeting: DateTime.now().greeting,
          avatar: Assets.images.profile.provider(),
        ),
        AppSize.h(AppSize.md),
        BalanceCard(snapshot: snapshot),
        AppSize.h(AppSize.md),
        WalletActions(
          onSend: () => _openSendMoney(context),
          onAddMoney: () => _openAddMoney(context),
          onSave: () => _goToTab(context, 1),
          onHistory: () => _goToTab(context, 2),
        ),
        if (showActivityLabel) ...[
          AppSize.h(AppSize.lg),
          SectionHeader(
            title: 'Activity',
            actionLabel: 'See all',
            onAction: () => _goToTab(context, 2),
          ),
        ],
      ],
    );
  }

  void _openSendMoney(BuildContext context) {
    unawaited(context.pushNamed(RoutesName.sendMoney));
  }

  /// Savings and Activity are destinations, so they switch tab rather than
  /// pushing a second copy over the shell.
  void _goToTab(BuildContext context, int index) =>
      context.goNamed(switch (index) {
        1 => RoutesName.savings,
        2 => RoutesName.activity,
        _ => RoutesName.wallet,
      });

  void _openAddMoney(BuildContext context) {
    unawaited(context.pushNamed(RoutesName.addMoney));
  }
}
