import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/constants/app_color.dart';
import 'package:novapay/core/constants/app_size.dart';

enum ButtonVariant { primary, secondary, plain }

/// The app's only button; it carries the disabled palette and the loading
/// semantics so no call site has to remember them.
class CustomButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.expand = true,
    this.leading,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool expand;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final enabled = onPressed != null && !isLoading;

    final button = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.buttonMinHeight),
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: _background(colors),
          foregroundColor: _foreground(colors),
          // Disabled is a neutral fill; brand at low opacity reads as a
          // rendering fault in dark mode.
          disabledBackgroundColor: colors.fill,
          disabledForegroundColor: colors.subtext,
          elevation: 0,
          textStyle: Theme.of(context).textTheme.titleMedium,
          padding: const EdgeInsets.symmetric(horizontal: AppSize.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.radiusSm),
          ),
        ),
        child: isLoading
            ? Semantics(
                label: '$label, in progress',
                child: const _ButtonSpinner(),
              )
            : _Label(label: label, leading: leading),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Color _background(AppThemeColors colors) => switch (variant) {
    ButtonVariant.primary => colors.primary,
    ButtonVariant.secondary => colors.fill,
    ButtonVariant.plain => Colors.transparent,
  };

  Color _foreground(AppThemeColors colors) => switch (variant) {
    ButtonVariant.primary => AppColor.onBrand,
    ButtonVariant.secondary => colors.textHeading,
    ButtonVariant.plain => colors.primaryStrong,
  };
}

class _Label extends StatelessWidget {
  const _Label({required this.label, this.leading});

  final String label;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, textAlign: TextAlign.center);
    if (leading == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        leading!,
        AppSize.w(AppSize.sm),
        Flexible(child: text),
      ],
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSize.iconMd,
      width: AppSize.iconMd,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(
          DefaultTextStyle.of(context).style.color ?? AppColor.onBrand,
        ),
      ),
    );
  }
}
