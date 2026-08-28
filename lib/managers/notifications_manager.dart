import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// FCM push notifications (mobile only — web push is descoped; the web
/// scheduler gets its feedback through Firestore streams).
///
/// Phase A stub: token registration, permission flow, foreground display and
/// notification-tap deep-linking land in Phase C.
class NotificationsManager {
  final _log = Logger('NotificationsManager');

  Future<void> initPushNotifications(String userId) async {
    const METHOD = 'initPushNotifications';
    if (kIsWeb) {
      _log.info('$METHOD - web: push descoped');
      return;
    }
    _log.info('$METHOD - stub (Phase C)');
  }

  Future<void> dispose() async {}
}
