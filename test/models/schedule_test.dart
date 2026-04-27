import 'package:flutter_test/flutter_test.dart';
import 'package:krizot_app/models/schedule.dart';

void main() {
  group('Schedule model', () {
    final now = DateTime.now();
    final later = now.add(const Duration(hours: 8));

    final baseJson = {
      'id': 'sch-001',
      'stationId': 'st-001',
      'startTime': now.toIso8601String(),
      'endTime': later.toIso8601String(),
    };

    test('fromJson creates schedule without user (open)', () {
      final schedule = Schedule.fromJson(baseJson);
      expect(schedule.id, 'sch-001');
      expect(schedule.stationId, 'st-001');
      expect(schedule.userId, isNull);
      expect(schedule.isOpen, isTrue);
      expect(schedule.isCovered, isFalse);
      expect(schedule.isCritical, isFalse);
    });

    test('fromJson creates covered schedule when userId present', () {
      final json = {...baseJson, 'userId': 'user-001'};
      final schedule = Schedule.fromJson(json);
      expect(schedule.isCovered, isTrue);
      expect(schedule.isOpen, isFalse);
    });

    test('fromJson parses station info', () {
      final json = {
        ...baseJson,
        'station': {
          'id': 'st-001',
          'name': 'Alpha Station',
          'location': 'North Sector',
        },
      };
      final schedule = Schedule.fromJson(json);
      expect(schedule.station?.name, 'Alpha Station');
      expect(schedule.station?.location, 'North Sector');
    });

    test('fromJson parses user info', () {
      final json = {
        ...baseJson,
        'userId': 'user-001',
        'user': {
          'id': 'user-001',
          'name': 'J. Cohen',
          'email': 'j.cohen@krizot.com',
        },
      };
      final schedule = Schedule.fromJson(json);
      expect(schedule.user?.name, 'J. Cohen');
      expect(schedule.user?.initials, 'J.');
    });

    test('shiftTimeLabel formats correctly', () {
      final start = DateTime(2024, 4, 27, 7, 0);
      final end = DateTime(2024, 4, 27, 15, 0);
      final json = {
        'id': 'sch-001',
        'stationId': 'st-001',
        'startTime': start.toIso8601String(),
        'endTime': end.toIso8601String(),
      };
      final schedule = Schedule.fromJson(json);
      expect(schedule.shiftTimeLabel, '07:00-15:00');
    });

    test('copyWith creates new instance with updated fields', () {
      final schedule = Schedule.fromJson(baseJson);
      final updated = schedule.copyWith(userId: 'user-002');
      expect(updated.userId, 'user-002');
      expect(updated.id, schedule.id);
    });

    test('status CRITICAL is parsed correctly', () {
      final json = {...baseJson, 'status': 'CRITICAL'};
      final schedule = Schedule.fromJson(json);
      expect(schedule.isCritical, isTrue);
    });
  });

  group('UserInfo model', () {
    test('initials from full name', () {
      const user = UserInfo(
        id: '1',
        name: 'John Cohen',
        email: 'j.cohen@test.com',
      );
      expect(user.initials, 'JC');
    });

    test('initials from single name', () {
      const user = UserInfo(
        id: '1',
        name: 'John',
        email: 'john@test.com',
      );
      expect(user.initials, 'J');
    });

    test('initials uppercase', () {
      const user = UserInfo(
        id: '1',
        name: 'alice bob',
        email: 'alice@test.com',
      );
      expect(user.initials, 'AB');
    });
  });

  group('WeeklySchedule model', () {
    test('fromJson parses weekly schedule', () {
      final json = {
        'weekStart': '2024-04-27T00:00:00.000Z',
        'weekEnd': '2024-05-03T00:00:00.000Z',
        'days': [
          {'index': 0, 'date': '2024-04-27T00:00:00.000Z', 'dayName': 'Monday'},
          {'index': 1, 'date': '2024-04-28T00:00:00.000Z', 'dayName': 'Tuesday'},
        ],
        'grid': [
          {
            'station': {
              'id': 'st-001',
              'name': 'Alpha',
              'location': 'North',
            },
            'days': {
              '0': [
                {
                  'id': 'sch-001',
                  'stationId': 'st-001',
                  'startTime': '2024-04-27T07:00:00.000Z',
                  'endTime': '2024-04-27T15:00:00.000Z',
                },
              ],
              '1': [],
            },
          },
        ],
      };

      final weekly = WeeklySchedule.fromJson(json);
      expect(weekly.days.length, 2);
      expect(weekly.grid.length, 1);
      expect(weekly.grid[0].station.name, 'Alpha');
      expect(weekly.grid[0].days[0]?.length, 1);
      expect(weekly.grid[0].days[1]?.length, 0);
    });
  });

  group('ScheduleStats model', () {
    test('fromJson parses stats', () {
      final json = {
        'totalStations': 10,
        'activeStations': 8,
        'onDuty': 15,
        'openShifts': 3,
        'criticalShifts': 1,
      };
      final stats = ScheduleStats.fromJson(json);
      expect(stats.totalStations, 10);
      expect(stats.onDuty, 15);
      expect(stats.openShifts, 3);
      expect(stats.criticalShifts, 1);
    });

    test('fromJson handles alternative field names', () {
      final json = {
        'totalStations': 5,
        'activeStations': 4,
        'onDutyNow': 10,
        'openShiftsToday': 2,
        'criticalShifts': 0,
      };
      final stats = ScheduleStats.fromJson(json);
      expect(stats.onDuty, 10);
      expect(stats.openShifts, 2);
    });
  });
}
