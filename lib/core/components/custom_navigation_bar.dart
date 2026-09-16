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
/// bar notched around it.
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

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return SafeArea(
      top: false,
      // The circle is drawn outside the bar's own box, so the padding has to
      // leave room for it or SafeArea clips the lift away.
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
      builder: (context, centre, _) => CustomPaint(
        size: Size(double.infinity, height),
        painter: _NotchPainter(
          color: color,
          border: border,
          centre: centre,
          radius: radius,
        ),
      ),
    );
  }
}

class _NotchPainter extends CustomPainter {
  const _NotchPainter({
    required this.color,
    required this.border,
    required this.centre,
    required this.radius,
  });

  final Color color;
  final Color border;
  final double centre;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const corner = Radius.circular(AppSize.radiusXl);
    final body = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, corner));

    // The concave cut the raised circle sits in.
    final cut = Path()
      ..addOval(Rect.fromCircle(center: Offset(centre, 0), radius: radius));

    final shape = Path.combine(PathOperation.difference, body, cut);

    canvas
      ..drawPath(shape, Paint()..color = color)
      ..drawPath(
        shape,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  @override
  bool shouldRepaint(_NotchPainter old) =>
      old.centre != centre ||
      old.color != color ||
      old.border != border ||
      old.radius != radius;
}
