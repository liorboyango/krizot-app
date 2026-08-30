import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krizot_app/app_config/service_locator.dart';
import 'package:krizot_app/entities/app_user.dart';
import 'package:krizot_app/entities/shift.dart';
import 'package:krizot_app/entities/station.dart';
import 'package:krizot_app/managers/availability_manager.dart';
import 'package:krizot_app/managers/shifts_manager.dart';
import 'package:krizot_app/managers/training_manager.dart';
import 'package:krizot_app/services/availability_service.dart';
import 'package:krizot_app/services/day_requirements_service.dart';
import 'package:krizot_app/services/shifts_service.dart';
import 'package:krizot_app/services/training_service.dart';
import 'package:krizot_app/utils/time_util.dart';

/// Real ShiftsService + ShiftsManager over fake_cloud_firestore, registered
/// through GetIt exactly like production.
void main() {
  late FakeFirebaseFirestore firestore;
  late ShiftsManager manager;

  const employee = AppUser(
    id: 'emp1',
    displayName: 'Dana',
    email: 'dana@example.com',
    certifications: ['certGuard'],
  );

  setUp(() async {
    await locator.reset();
    firestore = FakeFirebaseFirestore();
    locator.registerSingleton<FirebaseFirestore>(firestore);
    locator.registerSingleton<ShiftsService>(ShiftsService());
    locator.registerSingleton<DayRequirementsService>(DayRequirementsService());
    manager = ShiftsManager();
    locator.registerSingleton<ShiftsManager>(manager);
    locator.registerSingleton<AvailabilityService>(AvailabilityService());
    locator.registerSingleton<AvailabilityManager>(AvailabilityManager());
    locator.registerSingleton<TrainingService>(TrainingService());
    locator.registerSingleton<TrainingManager>(TrainingManager());
  });

  tearDown(() async {
    await manager.dispose();
    await locator<AvailabilityManager>().dispose();
    await locator<TrainingManager>().dispose();
    await locator.reset();
  });

  Future<DocumentReference<Map<String, dynamic>>> seedShift({
    String? userId,
    required DateTime start,
    required DateTime end,
    String stationId = 'station1',
    bool acknowledged = false,
  }) =>
      firestore.collection('shifts').add({
        'stationId': stationId,
        'userId': userId,
        'start': Timestamp.fromDate(start),
        'end': Timestamp.fromDate(end),
        'dayKey': TimeUtil.dayKey(start),
        'status': userId == null ? 'open' : 'assigned',
        'acknowledged': acknowledged,
        'ackAt': null,
        'source': 'manual',
      });

  test('employee sees own upcoming shifts; current/next derived', () async {
    final now = DateTime.now();
    await seedShift(
      userId: employee.id,
      start: now.subtract(const Duration(hours: 1)),
      end: now.add(const Duration(hours: 1)),
    );
    await seedShift(
      userId: employee.id,
      start: now.add(const Duration(hours: 3)),
      end: now.add(const Duration(hours: 5)),
    );
    await seedShift(
      userId: 'someone-else',
      start: now.add(const Duration(hours: 3)),
      end: now.add(const Duration(hours: 5)),
    );

    await manager.initListeners(employee);
    final shifts = await manager.myShiftsStream
        .firstWhere((shifts) => shifts.length == 2);
    expect(shifts.every((s) => s.userId == employee.id), isTrue);
    expect(manager.currentShift, isNotNull);
    expect(manager.nextShift, isNotNull);
    expect(manager.nextShift!.start.isAfter(now), isTrue);
  });

  test('acknowledgeShift writes only the ack fields', () async {
    final now = DateTime.now();
    final ref = await seedShift(
      userId: employee.id,
      start: now.add(const Duration(hours: 1)),
      end: now.add(const Duration(hours: 3)),
    );
    await manager.initListeners(employee);

    expect(await manager.acknowledgeShift(ref.id), isTrue);
    final data = (await ref.get()).data()!;
    expect(data['acknowledged'], isTrue);
    expect(data['ackAt'], isNotNull);
    expect(data['userId'], employee.id);
    expect(data['status'], 'assigned');
  });

  test('pendingAckCountStream counts unacknowledged assigned shifts',
      () async {
    final now = DateTime.now();
    await seedShift(
      userId: employee.id,
      start: now.add(const Duration(hours: 1)),
      end: now.add(const Duration(hours: 2)),
    );
    await seedShift(
      userId: employee.id,
      start: now.add(const Duration(hours: 4)),
      end: now.add(const Duration(hours: 5)),
      acknowledged: true,
    );
    await manager.initListeners(employee);
    final count =
        await manager.pendingAckCountStream.firstWhere((count) => count > 0);
    expect(count, 1);
  });

  test('isEligible mirrors the backend predicate', () async {
    const station = Station(
      id: 'station1',
      name: 'Gate',
      location: 'North',
      requiredCertifications: ['certGuard'],
    );
    final now = DateTime.now();
    final shift = Shift(
      id: 'x',
      stationId: station.id,
      start: now.add(const Duration(hours: 1)),
      end: now.add(const Duration(hours: 3)),
      dayKey: TimeUtil.dayKey(now),
    );

    expect(manager.isEligible(employee, station, shift), isTrue);
    expect(
      manager.isEligible(
          employee.copyWith(certifications: []), station, shift),
      isFalse,
    );
    expect(
      manager.isEligible(
          employee.copyWith(status: UserStatus.sick), station, shift),
      isFalse,
    );
  });

  test('isEligible honours the availability calendar', () async {
    const managerUser = AppUser(
      id: 'mgr1',
      displayName: 'Mor',
      email: 'mor@example.com',
      role: UserRole.manager,
    );
    const station = Station(
      id: 'station1',
      name: 'Gate',
      location: 'North',
      requiredCertifications: ['certGuard'],
    );
    final now = DateTime.now();
    final shift = Shift(
      id: 'x',
      stationId: station.id,
      start: now.add(const Duration(hours: 1)),
      end: now.add(const Duration(hours: 3)),
      dayKey: TimeUtil.dayKey(now),
    );

    // A window elsewhere in the week that does NOT cover the shift.
    await firestore.collection('availability').add({
      'userId': employee.id,
      'start': Timestamp.fromDate(now.add(const Duration(hours: 5))),
      'end': Timestamp.fromDate(now.add(const Duration(hours: 8))),
    });

    final availabilityManager = locator<AvailabilityManager>();
    await availabilityManager.initListeners(managerUser);
    await availabilityManager.weekWindowsStream
        .firstWhere((windows) => windows.isNotEmpty);

    expect(manager.isEligible(employee, station, shift), isFalse);

    // A second window that covers the shift makes the user eligible again.
    await firestore.collection('availability').add({
      'userId': employee.id,
      'start': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
      'end': Timestamp.fromDate(now.add(const Duration(hours: 4))),
    });
    await availabilityManager.weekWindowsStream
        .firstWhere((windows) => windows.length == 2);

    expect(manager.isEligible(employee, station, shift), isTrue);
  });

  test('isEligible rejects candidates busy in a training session', () async {
    const managerUser = AppUser(
      id: 'mgr1',
      displayName: 'Mor',
      email: 'mor@example.com',
      role: UserRole.manager,
    );
    const station = Station(
      id: 'station1',
      name: 'Gate',
      location: 'North',
      requiredCertifications: ['certGuard'],
    );
    final now = DateTime.now();
    final shift = Shift(
      id: 'x',
      stationId: station.id,
      start: now.add(const Duration(hours: 1)),
      end: now.add(const Duration(hours: 3)),
      dayKey: TimeUtil.dayKey(now),
    );

    await firestore.collection('trainingSessions').add({
      'certificationId': 'certGuard',
      'type': 'tutoring',
      'traineeId': 'rookie',
      'trainerIds': [employee.id],
      'start': Timestamp.fromDate(now.add(const Duration(hours: 2))),
      'end': Timestamp.fromDate(now.add(const Duration(hours: 4))),
      'dayKey': TimeUtil.dayKey(now),
      'priority': 1,
    });

    final trainingManager = locator<TrainingManager>();
    await trainingManager.initListeners(managerUser);
    await trainingManager.weekSessionsStream
        .firstWhere((sessions) => sessions.isNotEmpty);

    expect(manager.isEligible(employee, station, shift), isFalse);
  });
}
