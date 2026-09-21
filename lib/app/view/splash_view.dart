import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/app/presentation/cubit/splash_cubit.dart';
import 'package:novapay/app/routes/routes_name.dart';
import 'package:novapay/core/components/custom_scaffold.dart';
import 'package:novapay/core/constants/app_color.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/gen/assets.gen.dart';

/// The brand screen the native launch window hands off to. It shows the same
/// wordmark on the same colour, so the handover is a continuation rather than
/// a second screen.
class SplashView extends StatelessWidget {
  const new({super.key});

  /// The width the native launch screen resolves the wordmark to, matched
  /// here so the handover does not resize it.
  static const double wordmarkWidth = 220;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<SplashCubit>();
        unawaited(cubit.start());
        return cubit;
      },
      child: const _SplashBody(),
    );
  }
}

class _SplashBody extends StatefulWidget {
  const new();

  @override
  State<_SplashBody> createState() => _SplashBodyState();
}

class _SplashBodyState extends State<_SplashBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SplashCubit.minimumHold,
  )..forward();

  late final Animation<double> _entrance = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashStatus>(
      listener: (context, status) {
        if (status == SplashStatus.ready) context.goNamed(RoutesName.wallet);
      },
      child: CustomScaffold(
        backgroundColor: AppColor.brand,
        safeArea: false,
        padding: EdgeInsets.zero,
        body: Center(
          child: FadeTransition(
            opacity: _entrance,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(_entrance),
              child: Assets.splash.wordmark.image(
                width: SplashView.wordmarkWidth,
                semanticLabel: 'Novapay',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
