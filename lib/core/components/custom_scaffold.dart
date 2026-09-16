import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/constants/app_size.dart';

/// Every screen's shell: it owns SafeArea, page padding and the app bar.
class CustomScaffold extends StatelessWidget {
  const new({
    required this.body,
    this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.bottomBar,
    this.backgroundColor,
    this.safeArea = true,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSize.md),
    super.key,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  /// A pinned call-to-action; it keeps clear of the keyboard and the gesture
  /// bar without the body having to reserve space for it.
  final Widget? bottomBar;
  final Color? backgroundColor;
  final bool safeArea;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final heading = title;

    Widget content = Padding(padding: padding, child: body);
    if (safeArea) content = SafeArea(bottom: false, child: content);

    return Scaffold(
      backgroundColor: backgroundColor ?? colors.background,
      appBar: heading == null
          ? null
          : AppBar(
              title: Text(heading),
              automaticallyImplyLeading: showBackButton,
              leading: showBackButton && onBackPressed != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back',
                      onPressed: onBackPressed,
                    )
                  : null,
              actions: actions,
            ),
      body: content,
      bottomNavigationBar: bottomBar == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSize.md,
                  AppSize.sm,
                  AppSize.md,
                  AppSize.md,
                ),
                child: bottomBar,
              ),
            ),
    );
  }
}
