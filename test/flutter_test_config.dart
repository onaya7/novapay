import 'dart:async';

import 'package:alchemist/alchemist.dart';

/// CI goldens only: every machine renders with the bundled Ahem-based font,
/// so a golden taken on a CI runner matches one taken on a laptop. Platform
/// goldens (real system fonts, one file per OS) are off — this repo has no
/// per-OS golden set to keep in sync.
Future<void> testExecutable(FutureOr<void> Function() testMain) {
  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
    ),
    run: () async {
      await testMain();
    },
  );
}
