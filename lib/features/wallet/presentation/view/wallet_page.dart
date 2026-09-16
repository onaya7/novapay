import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/core/components/custom_scaffold.dart';
import 'package:novapay/core/components/section_header.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/core/extensions/date_time_extension.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/features/savings/presentation/view/savings_page.dart';
import 'package:novapay/features/send_money/presentation/view/send_money_page.dart';
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
        return ActivityRow(key: ValueKey(item.id), item: item);
      },
    );
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
          title: context.l10n.walletTitle,
          greeting: DateTime.now().greeting,
        ),
        AppSize.h(AppSize.md),
        BalanceCard(snapshot: snapshot),
        AppSize.h(AppSize.md),
        WalletActions(
          onSend: () => _openSendMoney(context),
          onSave: () => _openSavings(context),
        ),
        if (showActivityLabel) ...[
          AppSize.h(AppSize.lg),
          const SectionHeader(title: 'Activity'),
        ],
      ],
    );
  }

  void _openSendMoney(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SendMoneyPage()));
  }

  void _openSavings(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SavingsPage()));
  }
}
