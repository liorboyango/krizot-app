import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krizot_app/app_config/service_locator.dart';
import 'package:krizot_app/entities/certification.dart';
import 'package:krizot_app/entities/station.dart';
import 'package:krizot_app/entities/time_window.dart';
import 'package:krizot_app/managers/stations_manager.dart';
import 'package:krizot_app/services/certifications_service.dart';
import 'package:krizot_app/services/stations_service.dart';

void main() {
  late StationsManager manager;

  setUp(() async {
    await locator.reset();
    locator.registerSingleton<FirebaseFirestore>(FakeFirebaseFirestore());
    locator.registerSingleton<StationsService>(StationsService());
    locator
        .registerSingleton<CertificationsService>(CertificationsService());
    manager = StationsManager();
    locator.registerSingleton<StationsManager>(manager);
  });

  tearDown(() async {
    await manager.dispose();
    await locator.reset();
  });

  test('station CRUD flows through the live stream', () async {
    await manager.initListeners('anyUser');

    final id = await manager.createStation(const Station(
      id: '',
      name: 'Station A',
      location: 'East wing',
      manningType: ManningType.onDemand,
      activeWindows: [TimeWindow(start: '08:00', end: '10:00')],
      requiredCertifications: ['certC'],
    ));
    expect(id, isNotNull);

    final created = await manager.stationsStream
        .firstWhere((stations) => stations.length == 1)
        .then((stations) => stations.single);
    expect(created.name, 'Station A');
    expect(created.manningType, ManningType.onDemand);
    expect(created.activeWindows.single.end, '10:00');
    expect(manager.stationById(created.id), isNotNull);

    expect(
      await manager.updateStation(Station(
        id: created.id,
        name: 'Station A2',
        location: created.location,
      )),
      isTrue,
    );
    await manager.stationsStream
        .firstWhere((stations) => stations.single.name == 'Station A2');

    expect(await manager.deleteStation(created.id), isTrue);
    await manager.stationsStream.firstWhere((stations) => stations.isEmpty);
  });

  test('certification catalog streams and lookups', () async {
    await manager.initListeners('anyUser');
    final id = await manager.createCertification(
        const Certification(id: '', name: 'Type C Responder'));
    expect(id, isNotNull);
    await manager.certificationsStream
        .firstWhere((certifications) => certifications.length == 1);
    expect(manager.certificationById(id!)?.name, 'Type C Responder');
  });
}
