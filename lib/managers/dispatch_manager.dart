import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import '../app_config/service_locator.dart';
import '../entities/app_user.dart';
import '../entities/emergency_event.dart';
import '../entities/event_type.dart';
import '../services/dispatch_service.dart';
import '../services/functions_service.dart';

/// Interface 3 state: event-type catalog, active emergency events, and the
/// signed-in user's own alerts (employee banner).
class DispatchManager {
  final _log = Logger('DispatchManager');
  final _dispatchService = locator<DispatchService>();

  final _eventTypes = BehaviorSubject<List<EventType>>();
  Stream<List<EventType>> get eventTypesStream => _eventTypes.stream;
  List<EventType> get eventTypes => _eventTypes.valueOrNull ?? const [];

  final _activeEvents = BehaviorSubject<List<EmergencyEvent>>();
  Stream<List<EmergencyEvent>> get activeEventsStream => _activeEvents.stream;
  List<EmergencyEvent> get activeEvents =>
      _activeEvents.valueOrNull ?? const [];

  /// Active events alerting the signed-in user.
  final _myAlerts = BehaviorSubject<List<EmergencyEvent>>();
  Stream<List<EmergencyEvent>> get myAlertsStream => _myAlerts.stream;
  List<EmergencyEvent> get myAlerts => _myAlerts.valueOrNull ?? const [];

  StreamSubscription? _eventTypesListener;
  StreamSubscription? _activeEventsListener;
  StreamSubscription? _myAlertsListener;

  /// Live acks of one event — cold pass-through; the dispatch card
  /// subscribes per event.
  Stream<List<EmergencyAck>> acksStreamFor(String eventId) =>
      _dispatchService.listenToAcks(eventId);

  Future<void> initListeners(AppUser user) async {
    const METHOD = 'initListeners';
    _log.info('$METHOD - START - role: ${user.role.name}');
    await cancelListeners();

    _myAlertsListener = _dispatchService.listenToUserAlerts(user.id).listen(
          (events) => _myAlerts.sink.add(events),
          onError: (Object e) => _log.severe('$METHOD - myAlerts: $e'),
        );

    if (user.role.canDispatch || user.role.canManage) {
      _eventTypesListener = _dispatchService.listenToEventTypes().listen(
            (types) => _eventTypes.sink.add(types),
            onError: (Object e) => _log.severe('$METHOD - eventTypes: $e'),
          );
      _activeEventsListener = _dispatchService.listenToActiveEvents().listen(
            (events) => _activeEvents.sink.add(events),
            onError: (Object e) => _log.severe('$METHOD - activeEvents: $e'),
          );
    }
  }

  Future<void> cancelListeners() async {
    await _eventTypesListener?.cancel();
    await _activeEventsListener?.cancel();
    await _myAlertsListener?.cancel();
    _eventTypesListener = null;
    _activeEventsListener = null;
    _myAlertsListener = null;
  }

  /// Fire the call-out. Server resolves responders and fans out FCM.
  Future<Map<String, dynamic>?> triggerEmergency(String eventTypeId) =>
      locator<FunctionsService>().triggerEmergency(eventTypeId);

  Future<bool> resolveEvent(String eventId, String resolvedBy) =>
      _dispatchService.resolveEvent(eventId, resolvedBy);

  Future<bool> acknowledgeEmergency(String eventId, String uid) =>
      _dispatchService.acknowledgeEmergency(eventId, uid);

  Future<String?> createEventType(EventType eventType) =>
      _dispatchService.createEventType(eventType);

  Future<bool> updateEventType(EventType eventType) =>
      _dispatchService.updateEventType(eventType);

  Future<bool> deleteEventType(String eventTypeId) =>
      _dispatchService.deleteEventType(eventTypeId);

  Future<void> dispose() async {
    await cancelListeners();
    await Future.wait([
      _eventTypes.close(),
      _activeEvents.close(),
      _myAlerts.close(),
    ]);
  }
}
