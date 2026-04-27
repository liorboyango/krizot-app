/// Unit tests for [ScheduleService] and [Schedule] model.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:krizot_app/models/schedule.dart';
import 'package:krizot_app/models/station.dart';
import 'package:krizot_app/models/user.dart';
import 'package:krizot_app/services/schedule_service.dart';

void main() {
  group('Schedule model', () {
    test('fromJson parses assigned schedule correctly', () {
      final json = {
        'id': 'schedule-1',
        'stationId': 'station-1',
        'userId': 'user-1',
        'startTime': '2024-04-27T07:00:00.000Z',
        'endTime': '2024-04-27T15:00:00.000Z',
        'notes': 'Morning shift',
      };
      final schedule = Schedule.fromJson(json);
      expect(schedule.id, equals('schedule-1'));
      expect(schedule.stationId, equals('station-1'));
      expect(schedule.userId, equals('user-1'));
      expect(schedule.isAssigned, isTrue);
      expect(schedule.notes, equals('Morning shift'));
    });

    test('fromJson parses unassigned schedule correctly', () {
      final json = {
        'id': 'schedule-2',
        'stationId': 'station-2',
        'startTime': '2024-04-27T15:00:00.000Z',
        'endTime': '2024-04-27T23:00:00.000Z',
      };
      final schedule = Schedule.fromJson(json);
      expect(schedule.userId, isNull);
      expect(schedule.isAssigned, isFalse);
    });

    test('fromJson parses nested station and user', () {
      final json = {
        'id': 'schedule-1',
        'stationId': 'station-1',
        'userId': 'user-1',
        'startTime': '2024-04-27T07:00:00.000Z',
        'endTime': '2024-04-27T15:00:00.000Z',
        'station': {
          'id': 'station-1',
          'name': 'Alpha',
          'location': 'North',
          'capacity': 4,
          'status': 'ACTIVE',
        },
        'user': {
          'id': 'user-1',
          'email': 'john@krizot.com',
          'name': 'John Cohen',
          'role': 'MANAGER',
        },
      };
      final schedule = Schedule.fromJson(json);
      expect(schedule.station, isNotNull);
      expect(schedule.station!.name, equals('Alpha'));
      expect(schedule.user, isNotNull);
      expect(schedule.user!.name, equals('John Cohen'));
    });

    test('durationHours calculates correctly for 8-hour shift', () {
      final schedule = Schedule(
        id: 'schedule-1',
        stationId: 'station-1',
        startTime: DateTime(2024, 4, 27, 7, 0),
        endTime: DateTime(2024, 4, 27, 15, 0),
      );
      expect(schedule.durationHours, equals(8.0));
    });

    test('toJson serialises correctly', () {
      final schedule = Schedule(
        id: 'schedule-1',
        stationId: 'station-1',
        userId: 'user-1',
        startTime: DateTime.utc(2024, 4, 27, 7, 0),
        endTime: DateTime.utc(2024, 4, 27, 15, 0),
        notes: 'Morning shift',
      );
      final json = schedule.toJson();
      expect(json['stationId'], equals('station-1'));
      expect(json['userId'], equals('user-1'));
      expect(json['startTime'], contains('2024-04-27'));
      expect(json['endTime'], contains('2024-04-27'));
      expect(json['notes'], equals('Morning shift'));
    });

    test('copyWith creates updated copy', () {
      final schedule = Schedule(
        id: 'schedule-1',
        stationId: 'station-1',
        startTime: DateTime(2024, 4, 27, 7, 0),
        endTime: DateTime(2024, 4, 27, 15, 0),
      );
      final updated = schedule.copyWith(userId: 'user-2');
      expect(updated.userId, equals('user-2'));
      expect(updated.id, equals('schedule-1'));
    });
  });

  group('ScheduleStats model', () {
    test('fromJson parses stats shape 1 (onDuty)', () {
      final json = {
        'totalStations': 12,
        'onDuty': 8,
        'openShifts': 4,
        'criticalShifts': 1,
      };
      final stats = ScheduleStats.fromJson(json);
      expect(stats.totalStations, equals(12));
      expect(stats.onDuty, equals(8));
      expect(stats.openShifts, equals(4));
      expect(stats.criticalShifts, equals(1));
    });

    test('fromJson parses stats shape 2 (onDutyNow/openShiftsToday)', () {
      final json = {
        'totalStations': 10,
        'onDutyNow': 6,
        'openShiftsToday': 3,
        'criticalShifts': 2,
      };
      final stats = ScheduleStats.fromJson(json);
      expect(stats.onDuty, equals(6));
      expect(stats.openShifts, equals(3));
    });
  });

  group('CreateScheduleRequest', () {
    test('toJson includes required fields', () {
      final request = CreateScheduleRequest(
        stationId: 'station-1',
        startTime: DateTime.utc(2024, 4, 27, 7, 0),
        endTime: DateTime.utc(2024, 4, 27, 15, 0),
      );
      final json = request.toJson();
      expect(json['stationId'], equals('station-1'));
      expect(json['startTime'], isNotNull);
      expect(json['endTime'], isNotNull);
      expect(json.containsKey('userId'), isFalse);
    });

    test('toJson includes optional userId when provided', () {
      final request = CreateScheduleRequest(
        stationId: 'station-1',
        startTime: DateTime.utc(2024, 4, 27, 7, 0),
        endTime: DateTime.utc(2024, 4, 27, 15, 0),
        userId: 'user-1',
      );
      final json = request.toJson();
      expect(json['userId'], equals('user-1'));
    });
  });

  group('AssignmentRequest', () {
    test('toJson with scheduleId and userId', () {
      const request = AssignmentRequest(
        scheduleId: 'schedule-1',
        userId: 'user-1',
      );
      final json = request.toJson();
      expect(json['scheduleId'], equals('schedule-1'));
      expect(json['userId'], equals('user-1'));
      expect(json.containsKey('stationId'), isFalse);
    });

    test('toJson with stationId and time range', () {
      final request = AssignmentRequest(
        stationId: 'station-1',
        userId: 'user-1',
        startTime: DateTime.utc(2024, 4, 27, 7, 0),
        endTime: DateTime.utc(2024, 4, 27, 15, 0),
      );
      final json = request.toJson();
      expect(json['stationId'], equals('station-1'));
      expect(json['userId'], equals('user-1'));
      expect(json['startTime'], isNotNull);
      expect(json['endTime'], isNotNull);
    });
  });

  group('BulkAssignResult', () {
    test('fromJson parses shape 1 (succeeded/failed)', () {
      final json = {
        'data': {
          'succeeded': [
            {
              'id': 'schedule-1',
              'stationId': 'station-1',
              'userId': 'user-1',
              'startTime': '2024-04-27T07:00:00.000Z',
              'endTime': '2024-04-27T15:00:00.000Z',
            },
          ],
          'failed': [],
        },
      };
      final result = BulkAssignResult.fromJson(json);
      expect(result.succeeded, hasLength(1));
      expect(result.failed, isEmpty);
    });

    test('fromJson parses shape 2 (created/conflicts)', () {
      final json = {
        'data': {
          'created': [
            {
              'id': 'schedule-1',
              'stationId': 'station-1',
              'userId': 'user-1',
              'startTime': '2024-04-27T07:00:00.000Z',
              'endTime': '2024-04-27T15:00:00.000Z',
            },
          ],
          'conflicts': [
            {'type': 'OVERLAP', 'message': 'User already assigned'},
          ],
        },
      };
      final result = BulkAssignResult.fromJson(json);
      expect(result.succeeded, hasLength(1));
      expect(result.failed, hasLength(1));
    });
  });
}
