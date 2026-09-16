import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/money_text.dart';
import 'package:novapay/core/components/quick_action_tile.dart';
import 'package:novapay/core/components/section_header.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/components/status_chip.dart';
import 'package:novapay/core/constants/app_color.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/core/extensions/date_time_extension.dart';
import 'package:novapay/features/wallet/domain/entities/activity_item.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';

/// The greeting strip above the balance card. `title` falls back to naming
/// the surface when there is no local display name to greet.
class WalletHeader extends StatelessWidget {
  const new({
    required this.title,
    required this.greeting,
    this.avatar,
    super.key,
  });

  final String title;
  final String greeting;
  final ImageProvider? avatar;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;
    return Row(
      children: [
        AppAvatar(icon: Icons.account_balance_wallet_outlined, image: avatar),
        AppSize.w(AppSize.smd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: texts.bodySmall?.copyWith(color: colors.textSubheading),
              ),
              Text(title, style: texts.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// The brand card: what may be spent, what is still in flight, and a toggle
/// for anyone who does not want their balance readable over their shoulder.
class BalanceCard extends StatefulWidget {
  const new({required this.snapshot, super.key});

  final WalletSnapshot snapshot;

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final texts = Theme.of(context).textTheme;
    final snapshot = widget.snapshot;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSize.mdl),
      decoration: BoxDecoration(
        color: AppColor.brand,
        borderRadius: BorderRadius.circular(AppSize.radiusXl),
        boxShadow: AppSize.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Available balance',
                style: texts.bodySmall?.copyWith(color: AppColor.onBrand),
              ),
              AppSize.w(AppSize.sm),
              _HideToggle(
                hidden: _hidden,
                onChanged: (value) => setState(() => _hidden = value),
              ),
            ],
          ),
          AppSize.h(AppSize.xs),
          // Scaled down rather than wrapped or clipped: a balance an order of
          // magnitude larger must still read as one line.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _hidden
                ? Text(
                    '••••••',
                    style: texts.displayMedium?.copyWith(
                      color: AppColor.onBrand,
                    ),
                  )
                : MoneyText(
                    amount: snapshot.available,
                    label: 'Available balance',
                    style: texts.displayMedium?.copyWith(
                      color: AppColor.onBrand,
                    ),
                  ),
          ),
          // Only shown when it differs from available; repeating the same
          // figure twice is noise, not reassurance.
          if (snapshot.hasPending) ...[
            AppSize.h(AppSize.smd),
            _PendingPill(snapshot: snapshot),
            AppSize.h(AppSize.md),
            const Divider(color: AppColor.white24, height: 1),
            AppSize.h(AppSize.md),
            Row(
              children: [
                Text(
                  'Wallet balance',
                  style: texts.bodySmall?.copyWith(color: AppColor.onBrand),
                ),
                const Spacer(),
                if (_hidden)
                  Text(
                    '••••••',
                    style: texts.labelLarge?.copyWith(color: AppColor.onBrand),
                  )
                else
                  MoneyText(
                    amount: snapshot.confirmed,
                    label: 'Wallet balance',
                    style: texts.labelLarge?.copyWith(color: AppColor.onBrand),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HideToggle extends StatelessWidget {
  const _HideToggle({required this.hidden, required this.onChanged});

  final bool hidden;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSize.touchTarget,
      width: AppSize.touchTarget,
      child: IconButton(
        onPressed: () => onChanged(!hidden),
        iconSize: AppSize.iconMd,
        color: AppColor.onBrand,
        tooltip: hidden ? 'Show balance' : 'Hide balance',
        icon: Icon(hidden ? Icons.visibility_off : Icons.visibility),
      ),
    );
  }
}

class _PendingPill extends StatelessWidget {
  const _PendingPill({required this.snapshot});

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
        borderRadius: BorderRadius.circular(AppSize.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule,
            size: AppSize.iconSm,
            color: AppColor.onBrand,
          ),
          AppSize.w(AppSize.sm),
          MoneyText(
            amount: snapshot.pending,
            label: 'Sending',
            style: texts.labelMedium?.copyWith(color: AppColor.onBrand),
          ),
          AppSize.w(AppSize.xs),
          Text(
            'sending',
            style: texts.labelMedium?.copyWith(color: AppColor.onBrand),
          ),
        ],
      ),
    );
  }
}

/// The wallet's four jobs. Every one of them does something.
class WalletActions extends StatelessWidget {
  const new({
    required this.onSend,
    required this.onAddMoney,
    required this.onSave,
    required this.onHistory,
    super.key,
  });

  final VoidCallback onSend;
  final VoidCallback onAddMoney;
  final VoidCallback onSave;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return QuickActionRow(
      tiles: [
        QuickActionTile(icon: Icons.arrow_upward, label: 'Send', onTap: onSend),
        QuickActionTile(icon: Icons.add, label: 'Add money', onTap: onAddMoney),
        QuickActionTile(
          icon: Icons.savings_outlined,
          label: 'Save',
          onTap: onSave,
        ),
        QuickActionTile(
          icon: Icons.receipt_long_outlined,
          label: 'History',
          onTap: onHistory,
        ),
      ],
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

    return Container(
      constraints: const BoxConstraints(minHeight: AppSize.rowMinHeight),
      padding: const EdgeInsets.all(AppSize.smd),
      decoration: BoxDecoration(
        color: colors.cards,
        borderRadius: BorderRadius.circular(AppSize.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(item: item),
          AppSize.w(AppSize.smd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: texts.labelLarge),
                AppSize.h(AppSize.xs),
                Text(
                  '${item.occurredAt.dayLabel} · ${item.occurredAt.timeLabel}',
                  style: texts.bodySmall?.copyWith(color: colors.subtext),
                ),
                if (_chipFor(item.status) case (final label, final tone)) ...[
                  AppSize.h(AppSize.sm),
                  StatusChip(label: label, tone: tone),
                ],
                if (item.note case final note?) ...[
                  AppSize.h(AppSize.sm),
                  Text(
                    note,
                    style: texts.bodySmall?.copyWith(
                      color: colors.textSubheading,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppSize.w(AppSize.sm),
          MoneyText(
            amount: item.amount,
            signed: true,
            style: texts.labelLarge?.copyWith(
              color: item.isDebit ? colors.textHeading : AppColor.success,
            ),
          ),
        ],
      ),
    );
  }
}

/// Null for a settled row: a list where every row is badged has no signal in
/// the badge. Word and tone come from one place so they cannot drift apart —
/// and an unknown outcome is not a failure, so it is not painted like one.
(String, ChipTone)? _chipFor(ActivityStatus status) => switch (status) {
  ActivityStatus.settled => null,
  ActivityStatus.pending => ('Pending', ChipTone.pending),
  ActivityStatus.rejected => ('Not sent', ChipTone.danger),
  ActivityStatus.unresolved => ('Unresolved', ChipTone.pending),
};

class _Avatar extends StatelessWidget {
  const _Avatar({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      height: AppSize.xxl,
      width: AppSize.xxl,
      decoration: BoxDecoration(
        color: item.isDebit ? colors.fill : colors.successSurface,
        shape: BoxShape.circle,
      ),
      child: Icon(
        item.isDebit ? Icons.arrow_upward : Icons.arrow_downward,
        size: AppSize.iconMd,
        color: item.isDebit ? colors.textSubheading : AppColor.success,
      ),
    );
  }
}

/// Stands in for a list of rows while the first load runs.
class ActivitySkeleton extends StatelessWidget {
  const new({this.rows = 6, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows; i++) ...[
          const SkeletonBox(
            height: AppSize.rowMinHeight,
            radius: AppSize.radiusLg,
          ),
          AppSize.h(AppSize.smd),
        ],
      ],
    );
  }
}

/// Stands in for the header, card, actions and three rows while the first
/// load runs, shaped so nothing shifts when the data lands.
class WalletSkeleton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SkeletonBox(
              height: 44,
              width: 44,
              radius: AppSize.radiusPill,
            ),
            AppSize.w(AppSize.smd),
            const Expanded(child: SkeletonBox(height: 40)),
          ],
        ),
        AppSize.h(AppSize.md),
        const SkeletonBox(height: 172, radius: AppSize.radiusXl),
        AppSize.h(AppSize.md),
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) AppSize.w(AppSize.smd),
              const Expanded(
                child: SkeletonBox(height: 56, radius: AppSize.radiusLg),
              ),
            ],
          ],
        ),
        AppSize.h(AppSize.lg),
        const SkeletonBox(height: 24, width: 120),
        AppSize.h(AppSize.md),
        for (var i = 0; i < 3; i++) ...[
          const SkeletonBox(
            height: AppSize.rowMinHeight,
            radius: AppSize.radiusLg,
          ),
          AppSize.h(AppSize.smd),
        ],
      ],
    );
  }
}
