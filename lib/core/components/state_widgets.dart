import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/constants/app_size.dart';

/// Centered indeterminate spinner, for waits a skeleton cannot describe.
class LoadingIndicator extends StatelessWidget {
  const new({this.size = AppSize.iconMd, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

/// A grey block the size of the content it stands in for, so nothing shifts
/// when the data lands.
class SkeletonBox extends StatelessWidget {
  const new({
    required this.height,
    this.width = double.infinity,
    this.radius = AppSize.radiusSm,
    super.key,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppThemeColors.of(context).fill,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// What happened, what it means, what to do — never a raw error code.
class AppErrorState extends StatelessWidget {
  const new({required this.message, this.onRetry, this.retryLabel, super.key});

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: Icons.cloud_off,
      message: message,
      action: onRetry == null
          ? null
          : CustomButton(
              label: retryLabel ?? 'Try again',
              onPressed: onRetry,
              variant: ButtonVariant.secondary,
              expand: false,
            ),
    );
  }
}

/// An empty list is a state with a next step, not a blank screen.
class AppEmptyState extends StatelessWidget {
  const new({
    required this.message,
    this.icon = Icons.inbox,
    this.action,
    super.key,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) =>
      _CenteredMessage(icon: icon, message: message, action: action);
}

/// Fills the viewport so pull-to-refresh works over an empty list too.
class PullToRefreshBody extends StatelessWidget {
  const new({
    required this.child,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Align(alignment: alignment, child: child),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSize.xl, color: colors.subtext),
            AppSize.h(AppSize.smd),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.textSubheading),
            ),
            if (action != null) ...[AppSize.h(AppSize.md), action!],
          ],
        ),
      ),
    );
  }
}
