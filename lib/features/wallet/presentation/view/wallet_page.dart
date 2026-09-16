import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/core/components/custom_scaffold.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';
import 'package:novapay/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:novapay/features/wallet/presentation/widgets/wallet_widgets.dart';
import 'package:novapay/l10n/l10n.dart';

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
      title: context.l10n.walletTitle,
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
        padding: EdgeInsets.symmetric(horizontal: AppSize.md),
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
              padding: const EdgeInsets.symmetric(horizontal: AppSize.md),
              child: BalanceCard(snapshot: snapshot),
            ),
            AppSize.h(AppSize.xxl),
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
        0,
        AppSize.md,
        AppSize.xxl,
      ),
      itemCount: snapshot.activity.length + 1,
      separatorBuilder: (context, index) =>
          index == 0 ? const SizedBox.shrink() : const Divider(),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSize.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BalanceCard(snapshot: snapshot),
                AppSize.h(AppSize.lg),
                Text('Activity', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          );
        }
        final item = snapshot.activity[index - 1];
        return ActivityRow(key: ValueKey(item.id), item: item);
      },
    );
  }
}
