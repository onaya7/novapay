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

class TransactionDetailPage extends StatelessWidget {
  const new({required this.item, super.key});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;
    final (label, tone) = _statusFor(item.status);

    return CustomScaffold(
      title: 'Transaction',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSize.h(AppSize.xl),
            Center(
              child: MoneyText(
                amount: item.amount,
                signed: true,
                label: item.isDebit ? 'Sent' : 'Received',
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
                SummaryRow(label: 'Description', value: item.title),
                SummaryRow(label: 'Date', value: item.occurredAt.dayLabel),
                SummaryRow(label: 'Time', value: item.occurredAt.timeLabel),
                SummaryRow(label: 'Reference', value: item.id),
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

  (String, ChipTone) _statusFor(ActivityStatus status) => switch (status) {
    ActivityStatus.settled => ('Settled', ChipTone.success),
    ActivityStatus.pending => ('Pending', ChipTone.pending),
    ActivityStatus.rejected => ('Not sent', ChipTone.danger),
    ActivityStatus.unresolved => ('Unresolved', ChipTone.pending),
  };
}
