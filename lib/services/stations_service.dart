import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../app_config/constants.dart';
import '../app_config/service_locator.dart';
import '../entities/station.dart';

class StationsService {
  final _log = Logger('StationsService');
  final _firestore = locator<FirebaseFirestore>();

  CollectionReference<Station> get _stations => _firestore
      .collection(Constants.COLLECTION_STATIONS)
      .withConverter<Station>(
        fromFirestore: (snapshot, _) => Station.fromDoc(snapshot),
        toFirestore: (station, _) => station.toMap(),
      );

  Stream<List<Station>> listenToStations() => _stations
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  Future<String?> createStation(Station station) async {
    const METHOD = 'createStation';
    _log.info('$METHOD - START - ${station.name}');
    try {
      final map = station.toMap()
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['updatedAt'] = FieldValue.serverTimestamp();
      final doc = await _firestore
          .collection(Constants.COLLECTION_STATIONS)
          .add(map);
      return doc.id;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return null;
    }
  }

  Future<bool> updateStation(Station station) async {
    const METHOD = 'updateStation';
    _log.info('$METHOD - START - ${station.id}');
    try {
      final map = station.toMap()..['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection(Constants.COLLECTION_STATIONS)
          .doc(station.id)
          .update(map);
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }

  Future<bool> deleteStation(String stationId) async {
    const METHOD = 'deleteStation';
    _log.info('$METHOD - START - $stationId');
    try {
      await _firestore
          .collection(Constants.COLLECTION_STATIONS)
          .doc(stationId)
          .delete();
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }
}
