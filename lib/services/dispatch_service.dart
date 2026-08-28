import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../app_config/constants.dart';
import '../app_config/service_locator.dart';
import '../entities/emergency_event.dart';
import '../entities/event_type.dart';

class DispatchService {
  final _log = Logger('DispatchService');
  final _firestore = locator<FirebaseFirestore>();

  CollectionReference<EventType> get _eventTypes => _firestore
      .collection(Constants.COLLECTION_EVENT_TYPES)
      .withConverter<EventType>(
        fromFirestore: (snapshot, _) => EventType.fromDoc(snapshot),
        toFirestore: (eventType, _) => eventType.toMap(),
      );

  CollectionReference<EmergencyEvent> get _events => _firestore
      .collection(Constants.COLLECTION_EMERGENCY_EVENTS)
      .withConverter<EmergencyEvent>(
        fromFirestore: (snapshot, _) => EmergencyEvent.fromDoc(snapshot),
        toFirestore: (event, _) => event.toMap(),
      );

  Stream<List<EventType>> listenToEventTypes() => _eventTypes
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  Stream<List<EmergencyEvent>> listenToActiveEvents() => _events
      .where('status', isEqualTo: EmergencyStatus.active.name)
      .orderBy('triggeredAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  /// Active events where [userId] is an alerted responder — employee banner.
  Stream<List<EmergencyEvent>> listenToUserAlerts(String userId) => _events
      .where('alertedUserIds', arrayContains: userId)
      .where('status', isEqualTo: EmergencyStatus.active.name)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  Stream<List<EmergencyAck>> listenToAcks(String eventId) => _firestore
      .collection(Constants.COLLECTION_EMERGENCY_EVENTS)
      .doc(eventId)
      .collection(Constants.COLLECTION_ACKS)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => EmergencyAck.fromDoc(doc)).toList());

  Future<String?> createEventType(EventType eventType) async {
    const METHOD = 'createEventType';
    _log.info('$METHOD - START - ${eventType.name}');
    try {
      final map = eventType.toMap()..['createdAt'] = FieldValue.serverTimestamp();
      final doc = await _firestore
          .collection(Constants.COLLECTION_EVENT_TYPES)
          .add(map);
      return doc.id;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return null;
    }
  }

  Future<bool> updateEventType(EventType eventType) async {
    const METHOD = 'updateEventType';
    _log.info('$METHOD - START - ${eventType.id}');
    try {
      await _firestore
          .collection(Constants.COLLECTION_EVENT_TYPES)
          .doc(eventType.id)
          .update(eventType.toMap());
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }

  Future<bool> deleteEventType(String eventTypeId) async {
    const METHOD = 'deleteEventType';
    _log.info('$METHOD - START - $eventTypeId');
    try {
      await _firestore
          .collection(Constants.COLLECTION_EVENT_TYPES)
          .doc(eventTypeId)
          .delete();
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }

  Future<bool> resolveEvent(String eventId, String resolvedBy) async {
    const METHOD = 'resolveEvent';
    _log.info('$METHOD - START - $eventId');
    try {
      await _firestore
          .collection(Constants.COLLECTION_EMERGENCY_EVENTS)
          .doc(eventId)
          .update({
        'status': EmergencyStatus.resolved.name,
        'resolvedBy': resolvedBy,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }

  /// Responder acknowledgement — creates own `acks/{uid}` doc (rules allow
  /// only the responder's own uid).
  Future<bool> acknowledgeEmergency(String eventId, String uid) async {
    const METHOD = 'acknowledgeEmergency';
    _log.info('$METHOD - START - event: $eventId');
    try {
      await _firestore
          .collection(Constants.COLLECTION_EMERGENCY_EVENTS)
          .doc(eventId)
          .collection(Constants.COLLECTION_ACKS)
          .doc(uid)
          .set({'ackAt': FieldValue.serverTimestamp()});
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }
}
