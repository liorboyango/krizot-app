import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import '../app_config/constants.dart';
import '../app_config/service_locator.dart';
import '../entities/training_session.dart';

class TrainingService {
  final _log = Logger('TrainingService');
  final _firestore = locator<FirebaseFirestore>();

  CollectionReference<TrainingSession> get _sessions => _firestore
      .collection(Constants.COLLECTION_TRAINING_SESSIONS)
      .withConverter<TrainingSession>(
        fromFirestore: (snapshot, _) => TrainingSession.fromDoc(snapshot),
        toFirestore: (session, _) => session.toMap(),
      );

  /// All sessions starting inside [start, end) — manager grid view.
  Stream<List<TrainingSession>> listenToSessionsForRange(
          DateTime start, DateTime end) =>
      _sessions
          .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('start', isLessThan: Timestamp.fromDate(end))
          .orderBy('start')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  /// Sessions the user participates in (as trainee or trainer) from [from]
  /// onward — merged from two queries because Firestore has no OR across
  /// different fields.
  Stream<List<TrainingSession>> listenToUserSessions(
      String userId, DateTime from) {
    final asTrainee = _sessions
        .where('traineeId', isEqualTo: userId)
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .orderBy('start')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    final asTrainer = _sessions
        .where('trainerIds', arrayContains: userId)
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .orderBy('start')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    return Rx.combineLatest2<List<TrainingSession>, List<TrainingSession>,
        List<TrainingSession>>(asTrainee, asTrainer, (trainee, trainer) {
      final byId = {for (final s in [...trainee, ...trainer]) s.id: s};
      return byId.values.toList()..sort((a, b) => a.start.compareTo(b.start));
    });
  }

  Future<String?> createSession(
      TrainingSession session, String createdBy) async {
    const METHOD = 'createSession';
    _log.info('$METHOD - START - cert: ${session.certificationId}');
    try {
      final map = session.toMap()
        ..['createdBy'] = createdBy
        ..['lastModifiedBy'] = createdBy
        ..['lastModifiedAt'] = FieldValue.serverTimestamp();
      final doc = await _firestore
          .collection(Constants.COLLECTION_TRAINING_SESSIONS)
          .add(map);
      return doc.id;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return null;
    }
  }

  Future<bool> updateSession(
    String sessionId,
    Map<String, dynamic> fields,
    String modifiedBy,
  ) async {
    const METHOD = 'updateSession';
    _log.info('$METHOD - START - $sessionId fields: ${fields.keys.join(',')}');
    try {
      await _firestore
          .collection(Constants.COLLECTION_TRAINING_SESSIONS)
          .doc(sessionId)
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

  Future<bool> deleteSession(String sessionId) async {
    const METHOD = 'deleteSession';
    _log.info('$METHOD - START - $sessionId');
    try {
      await _firestore
          .collection(Constants.COLLECTION_TRAINING_SESSIONS)
          .doc(sessionId)
          .delete();
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }
}
