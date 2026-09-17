import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:novapay/config/flavor/flavor_config.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/core/notifications/notification_service.dart';
import 'package:novapay/core/notifications/transfer_sync_notifier.dart';

class AppBlocObserver extends BlocObserver {
  const new();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

/// Step order is load-bearing: the box opens before the container resolves it.
Future<void> bootstrap(
  FlavorConfig config,
  FutureOr<Widget> Function() builder,
) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  await Hive.initFlutter();
  await Hive.openBox<dynamic>(config.hiveBoxName);

  if (!sl.isRegistered<FlavorConfig>()) {
    sl.registerSingleton<FlavorConfig>(config);
  }
  await configureDependencies();
  await sl<NotificationService>().initialize();
  await sl<TransferSyncNotifier>().start();

  Bloc.observer = const AppBlocObserver();

  runApp(await builder());
}
