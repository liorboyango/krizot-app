import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import '../app_config/service_locator.dart';
import '../entities/certification.dart';
import '../entities/station.dart';
import '../services/certifications_service.dart';
import '../services/stations_service.dart';

/// Stations + the certification catalog (small, always loaded together —
/// station editing and user tagging both need it).
class StationsManager {
  final _log = Logger('StationsManager');
  final _stationsService = locator<StationsService>();
  final _certificationsService = locator<CertificationsService>();

  final _stations = BehaviorSubject<List<Station>>();
  Stream<List<Station>> get stationsStream => _stations.stream;
  List<Station> get stations => _stations.valueOrNull ?? const [];

  final _certifications = BehaviorSubject<List<Certification>>();
  Stream<List<Certification>> get certificationsStream =>
      _certifications.stream;
  List<Certification> get certifications =>
      _certifications.valueOrNull ?? const [];

  StreamSubscription? _stationsListener;
  StreamSubscription? _certificationsListener;

  Station? stationById(String id) {
    for (final station in stations) {
      if (station.id == id) return station;
    }
    return null;
  }

  Certification? certificationById(String id) {
    for (final certification in certifications) {
      if (certification.id == id) return certification;
    }
    return null;
  }

  Future<void> initListeners(String userId) async {
    const METHOD = 'initListeners';
    _log.info('$METHOD - START');
    await cancelListeners();
    _stationsListener = _stationsService.listenToStations().listen(
          (stations) => _stations.sink.add(stations),
          onError: (Object e) => _log.severe('$METHOD - stations: $e'),
        );
    _certificationsListener =
        _certificationsService.listenToCertifications().listen(
              (certifications) => _certifications.sink.add(certifications),
              onError: (Object e) => _log.severe('$METHOD - certifications: $e'),
            );
  }

  Future<void> cancelListeners() async {
    await _stationsListener?.cancel();
    await _certificationsListener?.cancel();
    _stationsListener = null;
    _certificationsListener = null;
  }

  Future<String?> createStation(Station station) =>
      _stationsService.createStation(station);

  Future<bool> updateStation(Station station) =>
      _stationsService.updateStation(station);

  Future<bool> deleteStation(String stationId) =>
      _stationsService.deleteStation(stationId);

  Future<String?> createCertification(Certification certification) =>
      _certificationsService.createCertification(certification);

  Future<bool> updateCertification(Certification certification) =>
      _certificationsService.updateCertification(certification);

  Future<bool> deleteCertification(String certificationId) =>
      _certificationsService.deleteCertification(certificationId);

  Future<void> dispose() async {
    await cancelListeners();
    await Future.wait([_stations.close(), _certifications.close()]);
  }
}
