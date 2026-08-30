import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../app_config/constants.dart';
import '../app_config/service_locator.dart';
import '../entities/availability_window.dart';

class AvailabilityService {
  final _log = Logger('AvailabilityService');
  final _firestore = locator<FirebaseFirestore>();

  CollectionReference<AvailabilityWindow> get _windows => _firestore
      .collection(Constants.COLLECTION_AVAILABILITY)
      .withConverter<AvailabilityWindow>(
        fromFirestore: (snapshot, _) => AvailabilityWindow.fromDoc(snapshot),
        toFirestore: (window, _) => window.toMap(),
      );

  /// All users' windows overlapping [start, end) — scheduler grid.
  /// Single-field query on `end`; the `start < end-of-range` half is
  /// filtered client-side (windows are few and short-lived).
  Stream<List<AvailabilityWindow>> listenToWindowsForRange(
          DateTime start, DateTime end) =>
      _windows
          .where('end', isGreaterThan: Timestamp.fromDate(start))
          .orderBy('end')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => doc.data())
              .where((window) => window.start.isBefore(end))
              .toList());

  /// One user's windows ending after [from] — employee's own calendar.
  Stream<List<AvailabilityWindow>> listenToUserWindows(
          String userId, DateTime from) =>
      _windows
          .where('userId', isEqualTo: userId)
          .where('end', isGreaterThan: Timestamp.fromDate(from))
          .orderBy('end')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  Future<String?> createWindow(AvailabilityWindow window) async {
    const METHOD = 'createWindow';
    _log.info('$METHOD - START - user: ${window.userId}');
    try {
      final map = window.toMap()..['createdAt'] = FieldValue.serverTimestamp();
      final doc = await _firestore
          .collection(Constants.COLLECTION_AVAILABILITY)
          .add(map);
      return doc.id;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return null;
    }
  }

  Future<bool> updateWindow(
      String windowId, DateTime start, DateTime end) async {
    const METHOD = 'updateWindow';
    _log.info('$METHOD - START - $windowId');
    try {
      await _firestore
          .collection(Constants.COLLECTION_AVAILABILITY)
          .doc(windowId)
          .update({
        'start': Timestamp.fromDate(start),
        'end': Timestamp.fromDate(end),
      });
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }

  Future<bool> deleteWindow(String windowId) async {
    const METHOD = 'deleteWindow';
    _log.info('$METHOD - START - $windowId');
    try {
      await _firestore
          .collection(Constants.COLLECTION_AVAILABILITY)
          .doc(windowId)
          .delete();
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }
}
