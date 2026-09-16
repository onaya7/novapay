import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/constants/app_color.dart';
import 'package:novapay/core/constants/app_size.dart';

/// The app's only text field. The label is always visible and always in the
/// semantics tree, because a placeholder disappears the moment typing starts.
class CustomInputField extends StatelessWidget {
  const new({
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.prefix,
    this.autofocus = false,
    this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefix;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;
    final error = errorText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: texts.labelLarge?.copyWith(color: colors.textSubheading),
        ),
        AppSize.h(AppSize.sm),
        TextField(
          controller: controller,
          autofocus: autofocus,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: texts.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            prefixIconConstraints: const BoxConstraints(
              minWidth: AppSize.xxl,
              minHeight: AppSize.lg,
            ),
          ),
        ),
        if (error != null) ...[
          AppSize.h(AppSize.sm),
          Text(error, style: texts.bodySmall?.copyWith(color: AppColor.danger)),
        ] else if (helper != null) ...[
          AppSize.h(AppSize.sm),
          Text(
            helper!,
            style: texts.bodySmall?.copyWith(color: colors.subtext),
          ),
        ],
      ],
    );
  }
}

/// Keeps an amount field to digits and a single decimal point, so `Money`
/// never sees input it would have to reject.
class AmountInputFormatter extends TextInputFormatter {
  const new();

  static final RegExp _allowed = RegExp(r'^\d*\.?\d{0,2}$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => _allowed.hasMatch(newValue.text) ? newValue : oldValue;
}
