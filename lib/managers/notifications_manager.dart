import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../app_config/service_locator.dart';
import '../services/user_service.dart';
import '../widgets/screens/employee/employee_home_screen.dart';

/// FCM push notifications (mobile only — web push is descoped; the web
/// scheduler gets its feedback through Firestore streams).
///
/// Responsibilities: permission flow, token registration onto
/// users/{uid}.fcmTokens, foreground display via local notifications
/// (Android), and deep-linking notification taps to the employee home.
class NotificationsManager {
  final _log = Logger('NotificationsManager');

  static const _scheduleChannel = AndroidNotificationChannel(
    'krizot_schedule',
    'Schedule changes',
    description: 'Shift assignments and changes',
    importance: Importance.high,
  );
  static const _alertsChannel = AndroidNotificationChannel(
    'krizot_alerts',
    'Emergency alerts',
    description: 'High-priority emergency call-outs',
    importance: Importance.max,
  );

  final _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription? _tokenRefreshListener;
  StreamSubscription? _foregroundMessageListener;
  StreamSubscription? _messageOpenedListener;
  bool _initialized = false;

  Future<void> initPushNotifications(String userId) async {
    const METHOD = 'initPushNotifications';
    if (kIsWeb) {
      _log.info('$METHOD - web: push descoped');
      return;
    }
    _log.info('$METHOD - START');
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _log.warning('$METHOD - permission denied');
        return;
      }

      if (!_initialized) {
        _initialized = true;
        await _initLocalNotifications();
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      final token = await messaging.getToken();
      if (token != null) {
        await locator<UserService>()
            .addFCMToken(userId, token, defaultTargetPlatform.name);
      }
      await _tokenRefreshListener?.cancel();
      _tokenRefreshListener = messaging.onTokenRefresh.listen((newToken) =>
          locator<UserService>()
              .addFCMToken(userId, newToken, defaultTargetPlatform.name));

      // Foreground messages don't hit the system tray — mirror them to a
      // local notification on Android (iOS presents natively via the
      // foreground presentation options above).
      await _foregroundMessageListener?.cancel();
      _foregroundMessageListener =
          FirebaseMessaging.onMessage.listen(_showForegroundNotification);

      await _messageOpenedListener?.cancel();
      _messageOpenedListener =
          FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) _openFromMessage(initialMessage);
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (_) => _goHome(),
    );
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_scheduleChannel);
      await androidPlugin.createNotificationChannel(_alertsChannel);
      await androidPlugin.requestNotificationsPermission();
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    final isEmergency = message.data['type'] == 'emergency';
    final channel = isEmergency ? _alertsChannel : _scheduleChannel;
    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: isEmergency ? Priority.max : Priority.high,
        ),
      ),
    );
  }

  void _openFromMessage(RemoteMessage message) {
    const METHOD = '_openFromMessage';
    _log.info('$METHOD - type: ${message.data['type']}');
    _goHome();
  }

  void _goHome() {
    if (locator.isRegistered<GoRouter>()) {
      locator<GoRouter>().go(EmployeeHomeScreen.ROUTE_PATH);
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshListener?.cancel();
    await _foregroundMessageListener?.cancel();
    await _messageOpenedListener?.cancel();
  }
}
