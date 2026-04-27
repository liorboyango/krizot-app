import 'package:flutter_test/flutter_test.dart';
import 'package:krizot_app/models/station.dart';

void main() {
  group('StationStatus', () {
    test('fromString parses ACTIVE correctly', () {
      expect(StationStatus.fromString('ACTIVE'), StationStatus.active);
      expect(StationStatus.fromString('active'), StationStatus.active);
    });

    test('fromString parses CLOSED correctly', () {
      expect(StationStatus.fromString('CLOSED'), StationStatus.closed);
      expect(StationStatus.fromString('closed'), StationStatus.closed);
    });

    test('fromString defaults to active for unknown values', () {
      expect(StationStatus.fromString('UNKNOWN'), StationStatus.active);
    });

    test('toApiString returns correct values', () {
      expect(StationStatus.active.toApiString(), 'ACTIVE');
      expect(StationStatus.closed.toApiString(), 'CLOSED');
    });

    test('label returns human-readable text', () {
      expect(StationStatus.active.label, 'Active');
      expect(StationStatus.closed.label, 'Closed');
    });
  });

  group('Station', () {
    final testJson = {
      'id': 'abc123',
      'name': 'Alpha Station',
      'location': 'North Sector',
      'capacity': 4,
      'status': 'ACTIVE',
      'notes': 'Main entry point',
      'scheduleCount': 3,
      'createdAt': '2024-01-01T00:00:00.000Z',
      'updatedAt': '2024-01-02T00:00:00.000Z',
    };

    test('fromJson parses all fields correctly', () {
      final station = Station.fromJson(testJson);
      expect(station.id, 'abc123');
      expect(station.name, 'Alpha Station');
      expect(station.location, 'North Sector');
      expect(station.capacity, 4);
      expect(station.status, StationStatus.active);
      expect(station.notes, 'Main entry point');
      expect(station.scheduleCount, 3);
    });

    test('fromJson handles missing optional fields', () {
      final minimalJson = {
        'id': 'xyz',
        'name': 'Beta',
        'location': 'South',
        'capacity': 2,
        'status': 'CLOSED',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };
      final station = Station.fromJson(minimalJson);
      expect(station.notes, isNull);
      expect(station.scheduleCount, 0);
    });

    test('toJson serializes correctly', () {
      final station = Station.fromJson(testJson);
      final json = station.toJson();
      expect(json['id'], 'abc123');
      expect(json['name'], 'Alpha Station');
      expect(json['status'], 'ACTIVE');
    });

    test('copyWith creates updated copy', () {
      final station = Station.fromJson(testJson);
      final updated = station.copyWith(name: 'Beta Station', capacity: 6);
      expect(updated.name, 'Beta Station');
      expect(updated.capacity, 6);
      expect(updated.id, station.id); // unchanged
      expect(updated.location, station.location); // unchanged
    });

    test('equality is based on id', () {
      final s1 = Station.fromJson(testJson);
      final s2 = Station.fromJson({...testJson, 'name': 'Different Name'});
      expect(s1, equals(s2)); // same id
    });
  });

  group('PaginationMeta', () {
    test('fromJson parses correctly', () {
      final meta = PaginationMeta.fromJson({
        'page': 1,
        'limit': 20,
        'total': 45,
        'totalPages': 3,
      });
      expect(meta.page, 1);
      expect(meta.limit, 20);
      expect(meta.total, 45);
      expect(meta.totalPages, 3);
    });
  });

  group('StationStats', () {
    test('fromJson parses correctly', () {
      final stats = StationStats.fromJson({
        'total': 10,
        'active': 8,
        'closed': 2,
        'totalCapacity': 40,
      });
      expect(stats.total, 10);
      expect(stats.active, 8);
      expect(stats.closed, 2);
      expect(stats.totalCapacity, 40);
    });
  });
}
