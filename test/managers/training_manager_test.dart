import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krizot_app/app_config/service_locator.dart';
import 'package:krizot_app/entities/app_user.dart';
import 'package:krizot_app/entities/cert_requirement.dart';
import 'package:krizot_app/entities/certification.dart';
import 'package:krizot_app/entities/training_session.dart';
import 'package:krizot_app/managers/training_manager.dart';
import 'package:krizot_app/services/training_service.dart';

/// Staffing rules for the three training session types.
void main() {
  late TrainingManager manager;

  const target = Certification(
    id: 'certMedic',
    name: 'Medic',
    level: 3,
    simulationStaff: [
      CertRequirement(certificationId: 'certMedic', count: 2),
      CertRequirement(certificationId: 'certCommander', count: 1),
    ],
  );

  const medicA = AppUser(
      id: 'a',
      displayName: 'A',
      email: 'a@x.com',
      certifications: ['certMedic']);
  const medicB = AppUser(
      id: 'b',
      displayName: 'B',
      email: 'b@x.com',
      certifications: ['certMedic']);
  const commander = AppUser(
      id: 'c',
      displayName: 'C',
      email: 'c@x.com',
      certifications: ['certCommander']);
  const rookie = AppUser(
      id: 'r', displayName: 'R', email: 'r@x.com', certifications: []);

  setUp(() async {
    await locator.reset();
    locator.registerSingleton<FirebaseFirestore>(FakeFirebaseFirestore());
    locator.registerSingleton<TrainingService>(TrainingService());
    manager = TrainingManager();
    locator.registerSingleton<TrainingManager>(manager);
  });

  tearDown(() async {
    await manager.dispose();
    await locator.reset();
  });

  test('tutoring and spectation need exactly one certified trainer', () {
    for (final type in [TrainingType.tutoring, TrainingType.spectation]) {
      expect(manager.trainersSatisfy(target, type, [medicA]), isTrue);
      expect(manager.trainersSatisfy(target, type, [rookie]), isFalse);
      expect(manager.trainersSatisfy(target, type, [medicA, medicB]), isFalse);
      expect(manager.trainersSatisfy(target, type, []), isFalse);
    }
  });

  test('simulation staffing follows the certification definition', () {
    expect(
      manager.trainersSatisfy(
          target, TrainingType.simulation, [medicA, medicB, commander]),
      isTrue,
    );
    // Missing the commander.
    expect(
      manager
          .trainersSatisfy(target, TrainingType.simulation, [medicA, medicB]),
      isFalse,
    );
    // Only one medic of the required two.
    expect(
      manager
          .trainersSatisfy(target, TrainingType.simulation, [medicA, commander]),
      isFalse,
    );
  });

  test('simulation without a staffing definition falls back to one holder',
      () {
    const bare = Certification(id: 'certGuard', name: 'Guard', level: 1);
    const guard = AppUser(
        id: 'g',
        displayName: 'G',
        email: 'g@x.com',
        certifications: ['certGuard']);
    expect(
      manager.trainersSatisfy(bare, TrainingType.simulation, [guard]),
      isTrue,
    );
    expect(
      manager.trainersSatisfy(bare, TrainingType.simulation, [rookie]),
      isFalse,
    );
  });
}
