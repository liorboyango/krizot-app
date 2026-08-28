import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krizot_app/entities/app_user.dart';
import 'package:krizot_app/entities/emergency_event.dart';
import 'package:krizot_app/entities/event_type.dart';
import 'package:krizot_app/entities/shift.dart';
import 'package:krizot_app/entities/station.dart';
import 'package:krizot_app/entities/time_window.dart';

void main() {
  group('AppUser', () {
    test('round-trips through toMap/fromMap', () {
      final user = AppUser(
        id: 'u1',
        displayName: 'Dana',
        email: 'dana@example.com',
        role: UserRole.dispatcher,
        certifications: const ['c1', 'c2'],
        status: UserStatus.sick,
        createdAt: DateTime(2026, 8, 1, 12),
      );
      final restored = AppUser.fromMap('u1', user.toMap());
      expect(restored.displayName, 'Dana');
      expect(restored.role, UserRole.dispatcher);
      expect(restored.certifications, ['c1', 'c2']);
      expect(restored.status, UserStatus.sick);
      expect(restored.createdAt, DateTime(2026, 8, 1, 12));
    });

    test('unknown role/status fall back to safe defaults', () {
      final user = AppUser.fromMap('u1', {'role': 'boss', 'status': 'gone'});
      expect(user.role, UserRole.employee);
      expect(user.status, UserStatus.available);
    });

    test('hasAllCertifications', () {
      const user = AppUser(
          id: 'u1', displayName: '', email: '', certifications: ['a', 'b']);
      expect(user.hasAllCertifications(['a']), isTrue);
      expect(user.hasAllCertifications(['a', 'c']), isFalse);
      expect(user.hasAllCertifications([]), isTrue);
    });
  });

  group('Station', () {
    test('round-trips 24x7 wire value and windows', () {
      const station = Station(
        id: 's1',
        name: 'Station B',
        location: 'North gate',
        manningType: ManningType.aroundTheClock,
        requiredCertifications: ['certGuard'],
      );
      expect(station.toMap()['manningType'], '24x7');
      final restored = Station.fromMap('s1', station.toMap());
      expect(restored.manningType, ManningType.aroundTheClock);
      expect(restored.isAroundTheClock, isTrue);

      const onDemand = Station(
        id: 's2',
        name: 'Station A',
        location: 'East',
        manningType: ManningType.onDemand,
        activeWindows: [TimeWindow(start: '08:00', end: '10:00')],
      );
      final restored2 = Station.fromMap('s2', onDemand.toMap());
      expect(restored2.manningType, ManningType.onDemand);
      expect(restored2.activeWindows, hasLength(1));
      expect(restored2.activeWindows.first.start, '08:00');
    });
  });

  group('TimeWindow', () {
    test('parses and checks containment', () {
      const window = TimeWindow(start: '08:00', end: '10:00');
      expect(window.contains(const TimeOfDay(hour: 8, minute: 0)), isTrue);
      expect(window.contains(const TimeOfDay(hour: 9, minute: 59)), isTrue);
      expect(window.contains(const TimeOfDay(hour: 10, minute: 0)), isFalse);
      expect(window.contains(const TimeOfDay(hour: 7, minute: 59)), isFalse);
    });
  });

  group('Shift', () {
    test('round-trips with Timestamps and null userId', () {
      final shift = Shift(
        id: 'sh1',
        stationId: 's1',
        start: DateTime(2026, 9, 1, 8),
        end: DateTime(2026, 9, 1, 10),
        dayKey: '2026-09-01',
        source: ShiftSource.autoFill,
      );
      final map = shift.toMap();
      expect(map['start'], isA<Timestamp>());
      expect(map['userId'], isNull);
      final restored = Shift.fromMap('sh1', map);
      expect(restored.userId, isNull);
      expect(restored.isAssigned, isFalse);
      expect(restored.start, DateTime(2026, 9, 1, 8));
      expect(restored.source, ShiftSource.autoFill);
      expect(restored.acknowledged, isFalse);
    });

    test('overlaps()', () {
      final shift = Shift(
        id: 'sh1',
        stationId: 's1',
        start: DateTime(2026, 9, 1, 8),
        end: DateTime(2026, 9, 1, 10),
        dayKey: '2026-09-01',
      );
      expect(
          shift.overlaps(DateTime(2026, 9, 1, 9), DateTime(2026, 9, 1, 11)),
          isTrue);
      expect(
          shift.overlaps(DateTime(2026, 9, 1, 10), DateTime(2026, 9, 1, 12)),
          isFalse);
    });
  });

  group('EventType / EmergencyEvent', () {
    test('EventType round-trips', () {
      const type = EventType(
        id: 'e1',
        name: 'Event Type C',
        responderCertifications: ['certC'],
        stationIds: ['s1'],
        priority: EventPriority.critical,
        active: false,
      );
      final restored = EventType.fromMap('e1', type.toMap());
      expect(restored.priority, EventPriority.critical);
      expect(restored.active, isFalse);
      expect(restored.responderCertifications, ['certC']);
    });

    test('EmergencyEvent round-trips alerted users', () {
      const event = EmergencyEvent(
        id: 'ev1',
        eventTypeId: 'e1',
        eventTypeName: 'Event Type C',
        triggeredBy: 'dispatcher1',
        alertedUserIds: ['u1', 'u2'],
        alertedUsers: [
          AlertedUser(uid: 'u1', displayName: 'Dana'),
          AlertedUser(uid: 'u2', displayName: 'Noa'),
        ],
      );
      final restored = EmergencyEvent.fromMap('ev1', event.toMap());
      expect(restored.alertedUserIds, ['u1', 'u2']);
      expect(restored.alertedUsers.first.displayName, 'Dana');
      expect(restored.status, EmergencyStatus.active);
    });
  });
}
