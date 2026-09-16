import 'package:material_ui/material_ui.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/core/money/money_words.dart';

/// Shows an amount and announces it as words, because a screen reader renders
/// raw currency text as "naira two comma four eight zero".
class MoneyText extends StatelessWidget {
  const new({
    required this.amount,
    this.style,
    this.label,
    this.signed = false,
    super.key,
  });

  final Money amount;
  final TextStyle? style;

  /// Prepended to the spoken form, as in "Balance, two thousand naira".
  final String? label;

  /// Prints a leading + or - the way a statement row does.
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final prefix = label == null ? '' : '$label, ';
    final sign = signed && !amount.isNegative ? '+' : '';
    return Semantics(
      label: '$prefix${spokenMoney(amount)}',
      child: ExcludeSemantics(
        child: Text('$sign${amount.format()}', style: style),
      ),
    );
  }
}
