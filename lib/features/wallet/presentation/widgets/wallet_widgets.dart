import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/money_text.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/components/status_chip.dart';
import 'package:novapay/core/constants/app_color.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/core/extensions/date_time_extension.dart';
import 'package:novapay/features/wallet/domain/entities/activity_item.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';

/// The brand-blue card: available money large, committed money beneath it.
class BalanceCard extends StatelessWidget {
  const new({required this.snapshot, super.key});

  final WalletSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final texts = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSize.lg),
      decoration: BoxDecoration(
        color: AppColor.brand,
        borderRadius: BorderRadius.circular(AppSize.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available balance',
            style: texts.bodySmall?.copyWith(color: AppColor.onBrand),
          ),
          AppSize.h(AppSize.xs),
          MoneyText(
            amount: snapshot.available,
            label: 'Available balance',
            style: texts.displayMedium?.copyWith(color: AppColor.onBrand),
          ),
          if (snapshot.hasPending) ...[
            AppSize.h(AppSize.smd),
            _PendingLine(snapshot: snapshot),
          ],
        ],
      ),
    );
  }
}

class _PendingLine extends StatelessWidget {
  const _PendingLine({required this.snapshot});

  final WalletSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final texts = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSize.smd,
        vertical: AppSize.sm,
      ),
      decoration: BoxDecoration(
        color: AppColor.brandStrong,
        borderRadius: BorderRadius.circular(AppSize.radiusSm),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule,
            size: AppSize.iconSm,
            color: AppColor.onBrand,
          ),
          AppSize.w(AppSize.sm),
          Expanded(
            child: Text(
              'Sending',
              style: texts.bodySmall?.copyWith(color: AppColor.onBrand),
            ),
          ),
          MoneyText(
            amount: snapshot.pending,
            label: 'Sending',
            style: texts.labelLarge?.copyWith(color: AppColor.onBrand),
          ),
        ],
      ),
    );
  }
}

/// One activity row. Only unsettled rows carry a chip.
class ActivityRow extends StatelessWidget {
  const new({required this.item, super.key});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.rowMinHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSize.smd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(item: item),
            AppSize.w(AppSize.smd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: texts.titleMedium),
                  AppSize.h(AppSize.xs),
                  Text(
                    '${item.occurredAt.dayLabel} · '
                    '${item.occurredAt.timeLabel}',
                    style: texts.bodySmall?.copyWith(color: colors.subtext),
                  ),
                  if (item.needsChip) ...[
                    AppSize.h(AppSize.sm),
                    StatusChip(
                      label: item.status == ActivityStatus.failed
                          ? 'Not sent'
                          : 'Pending',
                      tone: item.status == ActivityStatus.failed
                          ? ChipTone.danger
                          : ChipTone.pending,
                    ),
                  ],
                ],
              ),
            ),
            AppSize.w(AppSize.sm),
            MoneyText(
              amount: item.amount,
              signed: true,
              style: texts.titleMedium?.copyWith(
                color: item.isDebit ? colors.textHeading : AppColor.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      height: AppSize.xxl,
      width: AppSize.xxl,
      decoration: BoxDecoration(color: colors.fill, shape: BoxShape.circle),
      child: Icon(
        item.isDebit ? Icons.arrow_upward : Icons.arrow_downward,
        size: AppSize.iconMd,
        color: item.isDebit ? colors.textSubheading : AppColor.success,
      ),
    );
  }
}

/// Stands in for the card and three rows while the first load runs.
class WalletSkeleton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(height: 148, radius: AppSize.radiusLg),
        AppSize.h(AppSize.lg),
        const SkeletonBox(height: 20, width: 120),
        AppSize.h(AppSize.md),
        for (var i = 0; i < 3; i++) ...[
          const SkeletonBox(height: AppSize.xxl),
          AppSize.h(AppSize.md),
        ],
      ],
    );
  }
}
