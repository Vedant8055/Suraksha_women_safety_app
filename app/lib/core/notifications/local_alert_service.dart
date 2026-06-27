import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Lightweight local notifications for on-device safety alerts (no FCM required).
class LocalAlertService {
  LocalAlertService._();

  static final LocalAlertService instance = LocalAlertService._();
  final _notifications = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> ensureReady() async {
    if (_ready) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'suraksha_route_guard',
            'Route guard alerts',
            description: 'Alerts when you leave your usual daily route.',
            importance: Importance.high,
          ),
        );
    _ready = true;
  }

  Future<void> showRouteDeviationAlert({
    required String title,
    required String body,
  }) async {
    await ensureReady();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'suraksha_route_guard',
        'Route guard alerts',
        channelDescription: 'Alerts when you leave your usual daily route.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _notifications.show(
      4102,
      title,
      body,
      details,
    );
  }

  Future<void> cancelRouteDeviationAlert() async {
    if (!_ready) return;
    await _notifications.cancel(4102);
  }
}
