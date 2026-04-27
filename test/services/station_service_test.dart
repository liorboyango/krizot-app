/// Unit tests for [StationService] and [Station] model.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:krizot_app/models/station.dart';
import 'package:krizot_app/models/api_response.dart';

void main() {
  group('Station model', () {
    test('fromJson parses active station correctly', () {
      final json = {
        'id': 'station-1',
        'name': 'Alpha Station',
        'location': 'North Sector',
        'capacity': 4,
        'status': 'ACTIVE',
        'notes': 'Main entrance station',
        'scheduleCount': 3,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-15T00:00:00.000Z',
      };
      final station = Station.fromJson(json);
      expect(station.id, equals('station-1'));
      expect(station.name, equals('Alpha Station'));
      expect(station.location, equals('North Sector'));
      expect(station.capacity, equals(4));
      expect(station.status, equals(StationStatus.active));
      expect(station.notes, equals('Main entrance station'));
      expect(station.scheduleCount, equals(3));
      expect(station.createdAt, isNotNull);
    });

    test('fromJson parses closed station correctly', () {
      final json = {
        'id': 'station-2',
        'name': 'Beta Station',
        'location': 'South Sector',
        'capacity': 2,
        'status': 'CLOSED',
      };
      final station = Station.fromJson(json);
      expect(station.status, equals(StationStatus.closed));
      expect(station.notes, isNull);
      expect(station.scheduleCount, equals(0));
    });

    test('fromJson defaults to active for unknown status', () {
      final json = {
        'id': 'station-3',
        'name': 'Gamma Station',
        'location': 'Central',
        'capacity': 6,
        'status': 'UNKNOWN',
      };
      final station = Station.fromJson(json);
      expect(station.status, equals(StationStatus.active));
    });

    test('toJson serialises correctly for create request', () {
      const station = Station(
        id: 'station-1',
        name: 'Alpha Station',
        location: 'North Sector',
        capacity: 4,
        status: StationStatus.active,
        notes: 'Test notes',
      );
      final json = station.toJson();
      expect(json['name'], equals('Alpha Station'));
      expect(json['location'], equals('North Sector'));
      expect(json['capacity'], equals(4));
      expect(json['status'], equals('ACTIVE'));
      expect(json['notes'], equals('Test notes'));
      // id should not be in create payload
      expect(json.containsKey('id'), isFalse);
    });

    test('toJson omits null notes', () {
      const station = Station(
        id: 'station-1',
        name: 'Alpha Station',
        location: 'North Sector',
        capacity: 4,
        status: StationStatus.active,
      );
      final json = station.toJson();
      expect(json.containsKey('notes'), isFalse);
    });

    test('copyWith creates updated copy', () {
      const station = Station(
        id: 'station-1',
        name: 'Alpha Station',
        location: 'North Sector',
        capacity: 4,
        status: StationStatus.active,
      );
      final updated = station.copyWith(capacity: 6, status: StationStatus.closed);
      expect(updated.capacity, equals(6));
      expect(updated.status, equals(StationStatus.closed));
      expect(updated.name, equals('Alpha Station'));
      expect(updated.id, equals('station-1'));
    });

    test('equality is based on id', () {
      const station1 = Station(
        id: 'station-1',
        name: 'Alpha',
        location: 'North',
        capacity: 4,
        status: StationStatus.active,
      );
      const station2 = Station(
        id: 'station-1',
        name: 'Different Name',
        location: 'South',
        capacity: 2,
        status: StationStatus.closed,
      );
      expect(station1, equals(station2));
    });
  });

  group('StationStatus', () {
    test('fromString parses ACTIVE', () {
      expect(StationStatus.fromString('ACTIVE'), equals(StationStatus.active));
      expect(StationStatus.fromString('active'), equals(StationStatus.active));
    });

    test('fromString parses CLOSED', () {
      expect(StationStatus.fromString('CLOSED'), equals(StationStatus.closed));
      expect(StationStatus.fromString('closed'), equals(StationStatus.closed));
    });

    test('toApiString returns uppercase', () {
      expect(StationStatus.active.toApiString(), equals('ACTIVE'));
      expect(StationStatus.closed.toApiString(), equals('CLOSED'));
    });

    test('label returns human-readable string', () {
      expect(StationStatus.active.label, equals('Active'));
      expect(StationStatus.closed.label, equals('Closed'));
    });
  });

  group('StationStats model', () {
    test('fromJson parses correctly', () {
      final json = {
        'total': 12,
        'active': 10,
        'closed': 2,
        'totalCapacity': 48,
      };
      final stats = StationStats.fromJson(json);
      expect(stats.total, equals(12));
      expect(stats.active, equals(10));
      expect(stats.closed, equals(2));
      expect(stats.totalCapacity, equals(48));
    });
  });

  group('CreateStationRequest', () {
    test('toJson includes all required fields', () {
      const request = CreateStationRequest(
        name: 'New Station',
        location: 'East Wing',
        capacity: 3,
      );
      final json = request.toJson();
      expect(json['name'], equals('New Station'));
      expect(json['location'], equals('East Wing'));
      expect(json['capacity'], equals(3));
      expect(json['status'], equals('ACTIVE'));
    });

    test('toJson omits empty notes', () {
      const request = CreateStationRequest(
        name: 'New Station',
        location: 'East Wing',
        capacity: 3,
      );
      final json = request.toJson();
      expect(json.containsKey('notes'), isFalse);
    });
  });

  group('UpdateStationRequest', () {
    test('toJson only includes non-null fields', () {
      const request = UpdateStationRequest(name: 'Updated Name');
      final json = request.toJson();
      expect(json['name'], equals('Updated Name'));
      expect(json.containsKey('location'), isFalse);
      expect(json.containsKey('capacity'), isFalse);
      expect(json.containsKey('status'), isFalse);
    });

    test('toJson includes all provided fields', () {
      const request = UpdateStationRequest(
        name: 'Updated',
        location: 'New Location',
        capacity: 5,
        status: StationStatus.closed,
      );
      final json = request.toJson();
      expect(json['name'], equals('Updated'));
      expect(json['location'], equals('New Location'));
      expect(json['capacity'], equals(5));
      expect(json['status'], equals('CLOSED'));
    });
  });
}
