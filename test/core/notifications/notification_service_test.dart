import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/notifications/notification_service.dart';

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin;

class _MockAndroidPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin;

class _MockIosPlugin extends Mock implements IOSFlutterLocalNotificationsPlugin;

void main() {
  late _MockPlugin plugin;
  late NotificationServiceImpl service;

  setUpAll(() {
    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(
      const AndroidNotificationChannel(
        'id',
        'name',
        importance: Importance.high,
      ),
    );
  });

  setUp(() {
    plugin = _MockPlugin();
    service = NotificationServiceImpl(plugin);
    when(() => plugin.initialize(settings: any(named: 'settings')))
        .thenAnswer((_) async => true);
  });

  test('initialize readies the channel and requests permission on both '
      'platforms', () async {
    final android = _MockAndroidPlugin();
    final ios = _MockIosPlugin();
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(android);
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(ios);
    when(android.requestNotificationsPermission).thenAnswer((_) async => true);
    when(() => android.createNotificationChannel(any()))
        .thenAnswer((_) async {});
    when(
      () => ios.requestPermissions(
        alert: any(named: 'alert'),
        badge: any(named: 'badge'),
        sound: any(named: 'sound'),
      ),
    ).thenAnswer((_) async => true);
    await service.initialize();

    verify(() => plugin.initialize(settings: any(named: 'settings'))).called(1);
    verify(() => android.createNotificationChannel(any())).called(1);
    verify(android.requestNotificationsPermission).called(1);
    verify(() => ios.requestPermissions(alert: true, badge: true, sound: true))
        .called(1);
  });

  test(
    'initialize tolerates a platform with no matching implementation',
    () async {
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(null);
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(null);

      await service.initialize();

      verify(() => plugin.initialize(settings: any(named: 'settings')))
          .called(1);
    },
  );

  test('show passes a title, body and the transfers channel', () async {
    when(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
      ),
    ).thenAnswer((_) async {});

    await service.show(
      title: 'Transfer sent',
      body: '₦5,000.00 is on its way.',
    );

    final captured = verify(
      () => plugin.show(
        id: captureAny(named: 'id'),
        title: 'Transfer sent',
        body: '₦5,000.00 is on its way.',
        notificationDetails: any(named: 'notificationDetails'),
      ),
    ).captured;
    expect(captured.single, isA<int>());
  });
}
