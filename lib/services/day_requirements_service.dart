import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../app_config/constants.dart';
import '../app_config/service_locator.dart';
import '../entities/day_requirement.dart';

class DayRequirementsService {
  final _log = Logger('DayRequirementsService');
  final _firestore = locator<FirebaseFirestore>();

  CollectionReference<DayRequirement> get _requirements => _firestore
      .collection(Constants.COLLECTION_DAY_REQUIREMENTS)
      .withConverter<DayRequirement>(
        fromFirestore: (snapshot, _) => DayRequirement.fromDoc(snapshot),
        toFirestore: (requirement, _) => requirement.toMap(),
      );

  /// Requirements for dayKeys in [startKey, endKey) — one week of the grid.
  Stream<List<DayRequirement>> listenToRange(String startKey, String endKey) =>
      _requirements
          .where('dayKey', isGreaterThanOrEqualTo: startKey)
          .where('dayKey', isLessThan: endKey)
          .orderBy('dayKey')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  /// Upsert — the doc id IS the dayKey, so a day has exactly one definition.
  Future<bool> setDayRequirement(
      DayRequirement requirement, String modifiedBy) async {
    const METHOD = 'setDayRequirement';
    _log.info('$METHOD - START - ${requirement.dayKey}');
    try {
      await _firestore
          .collection(Constants.COLLECTION_DAY_REQUIREMENTS)
          .doc(requirement.dayKey)
          .set({
        ...requirement.toMap(),
        'lastModifiedBy': modifiedBy,
        'lastModifiedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }
}
