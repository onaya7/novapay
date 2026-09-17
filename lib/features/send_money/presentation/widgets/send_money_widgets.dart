import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/amount_display.dart';
import 'package:novapay/core/components/custom_input_field.dart';
import 'package:novapay/core/components/summary_card.dart';
import 'package:novapay/core/constants/app_color.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/core/extensions/string_extension.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/features/send_money/domain/entities/bank.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_draft.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_receipt.dart';
import 'package:novapay/features/send_money/presentation/widgets/bank_avatar.dart';
import 'package:novapay/features/send_money/presentation/widgets/bank_picker_sheet.dart';
import 'package:novapay/l10n/l10n.dart';

/// Step one: which bank, then who the money is going to.
class RecipientStep extends StatelessWidget {
  const new({
    required this.draft,
    required this.banks,
    required this.onBankChanged,
    required this.onChanged,
    super.key,
  });

  final TransferDraft draft;
  final List<Bank> banks;
  final ValueChanged<Bank> onBankChanged;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showError = draft.recipient.isNotEmpty && !draft.recipientIsValid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BankSelector(bank: draft.bank, onTap: () => _pickBank(context)),
        AppSize.h(AppSize.mdl),
        CustomInputField(
          label: l10n.accountNumberLabel,
          hint: '0123456789',
          helper: l10n.accountNumberHelper,
          errorText: showError ? l10n.accountNumberError : null,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _pickBank(BuildContext context) async {
    final chosen = await showModalBottomSheet<Bank>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSize.radiusXl),
        ),
      ),
      builder: (_) => BankPickerSheet(banks: banks),
    );
    if (chosen != null) onBankChanged(chosen);
  }
}

class _BankSelector extends StatelessWidget {
  const _BankSelector({required this.bank, required this.onTap});

  final Bank? bank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final chosen = bank;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.bankLabel,
          style: texts.labelLarge?.copyWith(color: colors.textSubheading),
        ),
        AppSize.h(AppSize.sm),
        Material(
          color: colors.fill,
          borderRadius: BorderRadius.circular(AppSize.radiusMd),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSize.radiusMd),
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
              padding: const EdgeInsets.symmetric(horizontal: AppSize.md),
              child: Row(
                children: [
                  if (chosen != null) ...[
                    BankAvatar(bank: chosen, size: 28),
                    AppSize.w(AppSize.sm),
                  ],
                  Expanded(
                    child: Text(
                      chosen?.name ?? l10n.chooseBankHint,
                      style: texts.bodyLarge?.copyWith(
                        color: chosen == null ? colors.subtext : null,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: AppSize.iconMd,
                    color: colors.subtext,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Step two: the figure is the subject of the screen, so it is shown at
/// display size and the field that drives it is kept out of the way.
class AmountStep extends StatefulWidget {
  const new({required this.draft, required this.onChanged, super.key});

  final TransferDraft draft;
  final ValueChanged<String> onChanged;

  @override
  State<AmountStep> createState() => _AmountStepState();
}

class _AmountStepState extends State<AmountStep> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.draft.amountIsEntered
        ? widget.draft.amount.format(withSymbol: false)
        : '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _choose(Money amount) {
    final text = amount.format(withSymbol: false);
    _controller
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    widget.onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = widget.draft;
    final presets = <Money>[
      const Money.fromKobo(100000),
      const Money.fromKobo(500000),
      if (draft.available.kobo > 0) draft.available,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SummaryCard(
          children: [
            SummaryRow(
              label: l10n.fromWalletLabel,
              value: l10n.amountAvailable(draft.available.format()),
            ),
          ],
        ),
        AppSize.h(AppSize.xl),
        AmountDisplay(
          amount: draft.amount,
          label: l10n.sendingLabel,
          helper: _helper(l10n, draft),
          hasError: draft.amountIsEntered && !draft.hasEnough,
        ),
        AppSize.h(AppSize.lg),
        CustomInputField(
          label: l10n.amountFieldLabel,
          hint: '0.00',
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [AmountInputFormatter()],
          prefix: Padding(
            padding: const EdgeInsets.only(left: AppSize.md, right: AppSize.sm),
            child: Text('₦', style: Theme.of(context).textTheme.bodyLarge),
          ),
          autofocus: true,
          onChanged: widget.onChanged,
        ),
        AppSize.h(AppSize.md),
        QuickAmountChips(
          amounts: presets,
          selected: draft.amountIsEntered ? draft.amount : null,
          onSelected: _choose,
        ),
      ],
    );
  }

  String _helper(AppLocalizations l10n, TransferDraft draft) {
    if (!draft.amountIsEntered) return l10n.enterAmountHelper;
    if (!draft.hasEnough) return l10n.notEnoughHelper;
    return l10n.amountLeftAfter(draft.remaining.format());
  }
}

/// Step three: exactly what is about to happen, before it happens.
class ConfirmStep extends StatelessWidget {
  const new({required this.draft, super.key});

  final TransferDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.checkBeforeSend,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.textSubheading),
        ),
        AppSize.h(AppSize.md),
        SummaryCard(
          children: [
            SummaryRow(label: l10n.bankLabel, value: draft.bank?.name ?? '—'),
            SummaryRow(
              label: l10n.toLabel,
              value: draft.recipient.maskedAccountNumber,
            ),
            SummaryRow(label: l10n.amountLabel, value: draft.amount.format()),
            SummaryRow(label: l10n.feeLabel, value: l10n.noFee),
            SummaryRow(
              label: l10n.leftAfterLabel,
              value: draft.remaining.format(),
              emphasised: true,
            ),
          ],
        ),
        AppSize.h(AppSize.md),
        Text(
          l10n.savedBeforeSendingNote,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: colors.subtext),
        ),
      ],
    );
  }
}

/// The outcome. It never claims a send that has not been acknowledged.
class ReceiptStep extends StatelessWidget {
  const new({required this.receipt, super.key});

  final TransferReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final pending = receipt.isPending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSize.h(AppSize.xxl),
        Center(
          child: Container(
            height: 88,
            width: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: pending ? colors.fill : colors.successSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              pending ? Icons.schedule : Icons.check,
              size: AppSize.xl,
              color: pending ? colors.warning : AppColor.success,
            ),
          ),
        ),
        AppSize.h(AppSize.lg),
        Text(
          pending ? l10n.receiptQueuedHeadline : l10n.receiptSentHeadline,
          style: texts.headlineMedium,
          textAlign: TextAlign.center,
        ),
        AppSize.h(AppSize.sm),
        Text(
          pending
              ? l10n.receiptQueuedMessage
              : l10n.receiptSentMessage(
                  receipt.amount.format(),
                  receipt.bankName,
                  receipt.recipient.maskedAccountNumber,
                ),
          textAlign: TextAlign.center,
          style: texts.bodyMedium?.copyWith(color: colors.textSubheading),
        ),
        AppSize.h(AppSize.lg),
        SummaryCard(
          children: [
            SummaryRow(label: l10n.bankLabel, value: receipt.bankName),
            SummaryRow(
              label: l10n.toLabel,
              value: receipt.recipient.maskedAccountNumber,
            ),
            SummaryRow(
              label: l10n.amountLabel,
              value: receipt.amount.format(),
              emphasised: true,
            ),
          ],
        ),
      ],
    );
  }
}
