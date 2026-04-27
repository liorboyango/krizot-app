/// Riverpod providers for station state management.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/station.dart';
import '../models/api_response.dart';
import '../services/station_service.dart';

// Service provider
final stationServiceProvider = Provider<StationService>((ref) {
  return StationService();
});

/// Holds the current list query parameters and data.
class StationListState {
  const StationListState({
    this.params = const StationListParams(),
    this.stations = const [],
    this.pagination,
    this.isLoading = false,
    this.error,
  });

  final StationListParams params;
  final List<Station> stations;
  final Pagination? pagination;
  final bool isLoading;
  final String? error;

  StationListState copyWith({
    StationListParams? params,
    List<Station>? stations,
    Pagination? pagination,
    bool? isLoading,
    String? error,
  }) {
    return StationListState(
      params: params ?? this.params,
      stations: stations ?? this.stations,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Manages the station list with CRUD operations.
class StationsNotifier extends AsyncNotifier<StationListState> {
  late StationService _service;

  @override
  Future<StationListState> build() async {
    _service = ref.read(stationServiceProvider);
    return _fetchStations(const StationListParams());
  }

  Future<StationListState> _fetchStations(StationListParams params) async {
    try {
      final result = await _service.getStations(params);
      return StationListState(
        params: params,
        stations: result.data,
        pagination: result.pagination,
        isLoading: false,
      );
    } on ApiException catch (e) {
      return StationListState(params: params, error: e.userMessage);
    } on NetworkException catch (e) {
      return StationListState(params: params, error: e.message);
    }
  }

  /// Reload the station list with the current parameters.
  Future<void> refresh() async {
    final currentParams = state.valueOrNull?.params ?? const StationListParams();
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _fetchStations(currentParams));
  }

  /// Update the search query and reload.
  Future<void> search(String query) async {
    final currentParams = state.valueOrNull?.params ?? const StationListParams();
    final newParams = StationListParams(
      page: 1,
      limit: currentParams.limit,
      search: query.isEmpty ? null : query,
      status: currentParams.status,
      sortBy: currentParams.sortBy,
      sortOrder: currentParams.sortOrder,
    );
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _fetchStations(newParams));
  }

  /// Filter by status and reload.
  Future<void> filterByStatus(StationStatus? status) async {
    final currentParams = state.valueOrNull?.params ?? const StationListParams();
    final newParams = StationListParams(
      page: 1,
      limit: currentParams.limit,
      search: currentParams.search,
      status: status,
      sortBy: currentParams.sortBy,
      sortOrder: currentParams.sortOrder,
    );
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _fetchStations(newParams));
  }

  /// Navigate to a specific page.
  Future<void> goToPage(int page) async {
    final currentParams = state.valueOrNull?.params ?? const StationListParams();
    final newParams = StationListParams(
      page: page,
      limit: currentParams.limit,
      search: currentParams.search,
      status: currentParams.status,
      sortBy: currentParams.sortBy,
      sortOrder: currentParams.sortOrder,
    );
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _fetchStations(newParams));
  }

  /// Create a new station and refresh the list.
  Future<Station> createStation(CreateStationRequest request) async {
    final station = await _service.createStation(request);
    await refresh();
    return station;
  }

  /// Update an existing station and refresh the list.
  Future<Station> updateStation(String id, UpdateStationRequest request) async {
    final station = await _service.updateStation(id, request);
    final current = state.valueOrNull;
    if (current != null) {
      final updatedList = current.stations.map((s) => s.id == id ? station : s).toList();
      state = AsyncValue.data(current.copyWith(stations: updatedList));
    }
    return station;
  }

  /// Delete a station and refresh the list.
  Future<void> deleteStation(String id, {bool force = false}) async {
    await _service.deleteStation(id, force: force);
    final current = state.valueOrNull;
    if (current != null) {
      final updatedList = current.stations.where((s) => s.id != id).toList();
      state = AsyncValue.data(current.copyWith(stations: updatedList));
    }
  }
}

/// Provider for the [StationsNotifier].
final stationsNotifierProvider =
    AsyncNotifierProvider<StationsNotifier, StationListState>(StationsNotifier.new);

/// Convenience provider for the station list.
final stationsProvider = Provider<List<Station>>((ref) {
  return ref.watch(stationsNotifierProvider).valueOrNull?.stations ?? [];
});

/// Provider for station aggregate stats.
final stationStatsProvider = FutureProvider<StationStats>((ref) async {
  final service = ref.read(stationServiceProvider);
  return service.getStats();
});

/// Provider for a single station by ID.
final stationDetailProvider = FutureProvider.family<Station, String>((ref, id) async {
  final service = ref.read(stationServiceProvider);
  return service.getStation(id);
});
