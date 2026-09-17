import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/custom_scaffold.dart';
import 'package:novapay/core/components/money_text.dart';
import 'package:novapay/core/components/status_chip.dart';
import 'package:novapay/core/components/summary_card.dart';
import 'package:novapay/core/constants/app_color.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/core/extensions/date_time_extension.dart';
import 'package:novapay/features/wallet/domain/entities/activity_item.dart';
import 'package:novapay/l10n/l10n.dart';

class TransactionDetailPage extends StatelessWidget {
  const new({required this.item, super.key});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final (label, tone) = _statusFor(item.status, l10n);

    return CustomScaffold(
      title: l10n.transactionTitle,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSize.h(AppSize.xl),
            Center(
              child: MoneyText(
                amount: item.amount,
                signed: true,
                label: item.isDebit ? l10n.sentLabel : l10n.receivedLabel,
                style: texts.displayLarge?.copyWith(
                  color: item.isDebit ? colors.textHeading : AppColor.success,
                ),
              ),
            ),
            AppSize.h(AppSize.sm),
            Center(
              child: StatusChip(label: label, tone: tone),
            ),
            AppSize.h(AppSize.xl),
            SummaryCard(
              children: [
                SummaryRow(label: l10n.descriptionLabel, value: item.title),
                SummaryRow(
                  label: l10n.dateLabel,
                  value: item.occurredAt.dayLabel(
                    today: l10n.todayLabel,
                    yesterday: l10n.yesterdayLabel,
                  ),
                ),
                SummaryRow(
                  label: l10n.timeLabel,
                  value: item.occurredAt.timeLabel,
                ),
                SummaryRow(label: l10n.referenceLabel, value: item.id),
              ],
            ),
            if (item.note case final note?) ...[
              AppSize.h(AppSize.md),
              Text(
                note,
                textAlign: TextAlign.center,
                style: texts.bodySmall?.copyWith(color: colors.subtext),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (String, ChipTone) _statusFor(ActivityStatus status, AppLocalizations l10n) =>
      switch (status) {
        ActivityStatus.settled => (l10n.settledLabel, ChipTone.success),
        ActivityStatus.pending => (l10n.pendingLabel, ChipTone.pending),
        ActivityStatus.rejected => (l10n.notSentLabel, ChipTone.danger),
        ActivityStatus.unresolved => (l10n.unresolvedLabel, ChipTone.pending),
      };
}
