import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krizot_app/models/station.dart';
import 'package:krizot_app/providers/stations_provider.dart';
import 'package:krizot_app/services/stations_service.dart';

/// Mock stations service for testing.
class MockStationsService extends StationsService {
  List<Station> mockStations;
  StationStats? mockStats;
  bool shouldThrow;

  MockStationsService({
    this.mockStations = const [],
    this.mockStats,
    this.shouldThrow = false,
  });

  @override
  Future<StationsPage> getStations({
    String? search,
    String? status,
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    if (shouldThrow) {
      throw StationServiceException('Network error');
    }
    return StationsPage(
      stations: mockStations,
      pagination: PaginationMeta(
        page: page,
        limit: limit,
        total: mockStations.length,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<StationStats> getStats() async {
    if (shouldThrow) throw StationServiceException('Network error');
    return mockStats ??
        const StationStats(
          total: 0,
          active: 0,
          closed: 0,
          totalCapacity: 0,
        );
  }

  @override
  Future<Station> createStation(CreateStationRequest request) async {
    if (shouldThrow) throw StationServiceException('Create failed');
    final station = Station(
      id: 'new-id',
      name: request.name,
      location: request.location,
      capacity: request.capacity,
      status: StationStatus.fromString(request.status),
      notes: request.notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    mockStations = [...mockStations, station];
    return station;
  }

  @override
  Future<Station> updateStation(
      String id, UpdateStationRequest request) async {
    if (shouldThrow) throw StationServiceException('Update failed');
    final existing = mockStations.firstWhere((s) => s.id == id);
    final updated = existing.copyWith(
      name: request.name,
      location: request.location,
      capacity: request.capacity,
    );
    mockStations =
        mockStations.map((s) => s.id == id ? updated : s).toList();
    return updated;
  }

  @override
  Future<void> deleteStation(String id, {bool force = false}) async {
    if (shouldThrow) throw StationServiceException('Delete failed');
    mockStations = mockStations.where((s) => s.id != id).toList();
  }
}

Station _makeStation(String id, String name) => Station(
      id: id,
      name: name,
      location: 'Test Location',
      capacity: 4,
      status: StationStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  group('StationsState', () {
    test('initial state has correct defaults', () {
      const state = StationsState();
      expect(state.stations, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.searchQuery, '');
      expect(state.statusFilter, isNull);
      expect(state.currentPage, 1);
    });

    test('hasMore returns false when no pagination', () {
      const state = StationsState();
      expect(state.hasMore, isFalse);
    });

    test('hasMore returns true when more pages exist', () {
      final state = StationsState(
        pagination: const PaginationMeta(
          page: 1,
          limit: 20,
          total: 50,
          totalPages: 3,
        ),
        currentPage: 1,
      );
      expect(state.hasMore, isTrue);
    });

    test('copyWith clearError sets error to null', () {
      const state = StationsState(error: 'Some error');
      final updated = state.copyWith(clearError: true);
      expect(updated.error, isNull);
    });
  });

  group('StationsNotifier', () {
    late ProviderContainer container;
    late MockStationsService mockService;

    setUp(() {
      mockService = MockStationsService(
        mockStations: [
          _makeStation('1', 'Alpha'),
          _makeStation('2', 'Beta'),
        ],
      );
      container = ProviderContainer(
        overrides: [
          stationsServiceProvider.overrideWithValue(mockService),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('loadStations populates stations list', () async {
      await container.read(stationsProvider.notifier).loadStations();
      final state = container.read(stationsProvider);
      expect(state.stations.length, 2);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('loadStations sets error on failure', () async {
      mockService.shouldThrow = true;
      await container.read(stationsProvider.notifier).loadStations();
      final state = container.read(stationsProvider);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('deleteStation removes station from list', () async {
      await container.read(stationsProvider.notifier).loadStations();
      final success =
          await container.read(stationsProvider.notifier).deleteStation('1');
      expect(success, isTrue);
      final state = container.read(stationsProvider);
      expect(state.stations.any((s) => s.id == '1'), isFalse);
    });

    test('clearError removes error from state', () async {
      mockService.shouldThrow = true;
      await container.read(stationsProvider.notifier).loadStations();
      expect(container.read(stationsProvider).error, isNotNull);

      container.read(stationsProvider.notifier).clearError();
      expect(container.read(stationsProvider).error, isNull);
    });
  });
}
