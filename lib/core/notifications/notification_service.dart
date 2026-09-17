import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

/// A local, on-device notification. No push infrastructure is involved —
/// screens depend on this rather than the plugin, so a cubit-adjacent caller
/// can be tested against a stub without a platform channel.
abstract class NotificationService {
  /// Requests permission and readies the platform channel. Call once, at
  /// startup.
  Future<void> initialize();

  Future<void> show({required String title, required String body});
}

@LazySingleton(as: NotificationService)
class NotificationServiceImpl implements NotificationService {
  NotificationServiceImpl(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'transfers_synced',
        'Transfers',
        channelDescription: 'A queued transfer finished syncing',
        importance: Importance.high,
        priority: Priority.high,
      );

  @override
  Future<void> initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> show({required String title, required String body}) =>
      _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: _androidDetails,
          iOS: DarwinNotificationDetails(),
        ),
      );
}
