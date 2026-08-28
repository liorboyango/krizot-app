import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../app_config/constants.dart';
import '../app_config/service_locator.dart';
import '../entities/shift.dart';
import '../utils/time_util.dart';

class ShiftsService {
  final _log = Logger('ShiftsService');
  final _firestore = locator<FirebaseFirestore>();

  CollectionReference<Shift> get _shifts =>
      _firestore.collection(Constants.COLLECTION_SHIFTS).withConverter<Shift>(
            fromFirestore: (snapshot, _) => Shift.fromDoc(snapshot),
            toFirestore: (shift, _) => shift.toMap(),
          );

  /// All shifts starting inside [start, end) — manager grid view.
  Stream<List<Shift>> listenToShiftsForRange(DateTime start, DateTime end) =>
      _shifts
          .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('start', isLessThan: Timestamp.fromDate(end))
          .orderBy('start')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  /// A user's shifts from [from] onward — employee view.
  Stream<List<Shift>> listenToUserShifts(String userId, DateTime from) =>
      _shifts
          .where('userId', isEqualTo: userId)
          .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .orderBy('start')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  /// One-shot fetch of a user's shifts overlapping a day — used for
  /// client-side conflict checks before assignment.
  Future<List<Shift>?> getUserShiftsForDay(String userId, DateTime day) async {
    const METHOD = 'getUserShiftsForDay';
    try {
      final snapshot = await _shifts
          .where('userId', isEqualTo: userId)
          .where('dayKey', isEqualTo: TimeUtil.dayKey(day))
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return null;
    }
  }

  Future<String?> createShift(Shift shift, String createdBy) async {
    const METHOD = 'createShift';
    _log.info('$METHOD - START - station: ${shift.stationId}');
    try {
      final map = shift.toMap()
        ..['dayKey'] = TimeUtil.dayKey(shift.start)
        ..['status'] =
            (shift.userId != null ? ShiftStatus.assigned : ShiftStatus.open)
                .name
        ..['acknowledged'] = false
        ..['ackAt'] = null
        ..['createdBy'] = createdBy
        ..['lastModifiedBy'] = createdBy
        ..['lastModifiedAt'] = FieldValue.serverTimestamp();
      final doc =
          await _firestore.collection(Constants.COLLECTION_SHIFTS).add(map);
      return doc.id;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return null;
    }
  }

  /// Partial update; always stamps lastModifiedBy/At. The backend trigger
  /// resets `acknowledged` and notifies the assignee when relevant fields
  /// change.
  Future<bool> updateShift(
    String shiftId,
    Map<String, dynamic> fields,
    String modifiedBy,
  ) async {
    const METHOD = 'updateShift';
    _log.info('$METHOD - START - $shiftId fields: ${fields.keys.join(',')}');
    try {
      await _firestore
          .collection(Constants.COLLECTION_SHIFTS)
          .doc(shiftId)
          .update({
        ...fields,
        'lastModifiedBy': modifiedBy,
        'lastModifiedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }

  Future<bool> assignShift(String shiftId, String userId, String modifiedBy,
          {ShiftSource source = ShiftSource.manual}) =>
      updateShift(shiftId, {
        'userId': userId,
        'status': ShiftStatus.assigned.name,
        'source': source.name,
      }, modifiedBy);

  Future<bool> unassignShift(String shiftId, String modifiedBy) =>
      updateShift(shiftId, {
        'userId': null,
        'status': ShiftStatus.open.name,
      }, modifiedBy);

  Future<bool> deleteShift(String shiftId) async {
    const METHOD = 'deleteShift';
    _log.info('$METHOD - START - $shiftId');
    try {
      await _firestore
          .collection(Constants.COLLECTION_SHIFTS)
          .doc(shiftId)
          .delete();
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }

  /// Employee acknowledgement — writes ONLY the ack fields, matching the
  /// strict field mask in firestore.rules.
  Future<bool> acknowledgeShift(String shiftId) async {
    const METHOD = 'acknowledgeShift';
    _log.info('$METHOD - START - $shiftId');
    try {
      await _firestore
          .collection(Constants.COLLECTION_SHIFTS)
          .doc(shiftId)
          .update({
        'acknowledged': true,
        'ackAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }
}
