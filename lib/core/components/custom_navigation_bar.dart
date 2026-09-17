import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/constants/app_color.dart';
import 'package:novapay/core/constants/app_size.dart';

/// One destination. Tasks are pushed, not tabbed, so this list stays short.
@immutable
class NavigationTab {
  const NavigationTab({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// The bar, with the selected destination lifted out of it on a circle and the
/// bar notched around it. Translucent and blurred, so scrolling content is
/// visible passing behind it rather than vanishing under a solid block.
class CustomNavigationBar extends StatelessWidget {
  const new({
    required this.tabs,
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  final List<NavigationTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// How far the selected circle rises above the bar.
  static const double lift = 22;
  static const double barHeight = 64;
  static const double circle = 52;

  /// How much bottom space the bar actually occupies, for anything scrolling
  /// behind it to clear — the same arithmetic this widget lays itself out
  /// with, defined once so a list's padding can never drift from it.
  static double reservedHeight(BuildContext context) =>
      barHeight + lift + AppSize.smd + MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSize.md,
          lift,
          AppSize.md,
          AppSize.smd,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slot = constraints.maxWidth / tabs.length;
            return SizedBox(
              height: barHeight + lift,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _NotchedBar(
                      color: colors.cards,
                      border: colors.border,
                      notchCentre: slot * (currentIndex + 0.5),
                      radius: circle / 2 + 6,
                      height: barHeight,
                    ),
                  ),
                  for (var i = 0; i < tabs.length; i++)
                    Positioned(
                      left: slot * i,
                      width: slot,
                      bottom: 0,
                      top: 0,
                      child: _Destination(
                        tab: tabs[i],
                        isSelected: i == currentIndex,
                        onTap: () => onSelected(i),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final NavigationTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: tab.label,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isSelected)
                Container(
                  height: CustomNavigationBar.circle,
                  width: CustomNavigationBar.circle,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tab.icon,
                    size: AppSize.iconLg,
                    color: AppColor.onBrand,
                  ),
                )
              else
                Icon(tab.icon, size: AppSize.iconLg, color: colors.subtext),
              AppSize.h(AppSize.xs),
              Flexible(
                child: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: isSelected
                      ? texts.labelMedium?.copyWith(color: colors.textHeading)
                      : texts.labelMedium?.copyWith(color: colors.subtext),
                ),
              ),
              AppSize.h(AppSize.sm),
            ],
          ),
        ),
      ),
    );
  }
}

/// The blurred, tinted fill behind the crisp border and the raised circle —
/// sharp icons over a frosted band, the same shape as WhatsApp's tab bar.
class _NotchedBar extends StatelessWidget {
  const _NotchedBar({
    required this.color,
    required this.border,
    required this.notchCentre,
    required this.radius,
    required this.height,
  });

  final Color color;
  final Color border;
  final double notchCentre;
  final double radius;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Animated so the cut slides to the new tab rather than jumping.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: notchCentre),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (context, centre, _) => SizedBox(
        width: double.infinity,
        height: height,
        child: Stack(
          children: [
            ClipPath(
              clipper: _NotchClipper(centre: centre, radius: radius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: ColoredBox(color: color.withValues(alpha: 0.72)),
              ),
            ),
            CustomPaint(
              size: Size(double.infinity, height),
              painter: _NotchPainter(
                border: border,
                centre: centre,
                radius: radius,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The concave cut the raised circle sits in, minus a rounded-rect body.
Path _notchPath(Size size, double centre, double radius) {
  const corner = Radius.circular(AppSize.radiusXl);
  final body = Path()
    ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, corner));
  final cut = Path()
    ..addOval(Rect.fromCircle(center: Offset(centre, 0), radius: radius));
  return Path.combine(PathOperation.difference, body, cut);
}

class _NotchClipper extends CustomClipper<Path> {
  const _NotchClipper({required this.centre, required this.radius});

  final double centre;
  final double radius;

  @override
  Path getClip(Size size) => _notchPath(size, centre, radius);

  @override
  bool shouldReclip(_NotchClipper old) =>
      old.centre != centre || old.radius != radius;
}

class _NotchPainter extends CustomPainter {
  const _NotchPainter({
    required this.border,
    required this.centre,
    required this.radius,
  });

  final Color border;
  final double centre;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _notchPath(size, centre, radius),
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_NotchPainter old) =>
      old.centre != centre || old.border != border || old.radius != radius;
}
