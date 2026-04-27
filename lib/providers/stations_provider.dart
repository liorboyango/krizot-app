import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/station.dart';
import '../services/stations_service.dart';

/// State for the stations list screen.
class StationsState {
  final List<Station> stations;
  final PaginationMeta? pagination;
  final StationStats? stats;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String searchQuery;
  final String? statusFilter;
  final int currentPage;

  const StationsState({
    this.stations = const [],
    this.pagination,
    this.stats,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.searchQuery = '',
    this.statusFilter,
    this.currentPage = 1,
  });

  bool get hasMore =>
      pagination != null && currentPage < pagination!.totalPages;

  StationsState copyWith({
    List<Station>? stations,
    PaginationMeta? pagination,
    StationStats? stats,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? searchQuery,
    String? statusFilter,
    int? currentPage,
    bool clearError = false,
    bool clearStatusFilter = false,
  }) {
    return StationsState(
      stations: stations ?? this.stations,
      pagination: pagination ?? this.pagination,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Riverpod notifier for station management.
class StationsNotifier extends StateNotifier<StationsState> {
  final StationsService _service;

  StationsNotifier(this._service) : super(const StationsState());

  /// Load the first page of stations.
  Future<void> loadStations({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      currentPage: 1,
    );

    try {
      final result = await _service.getStations(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        status: state.statusFilter,
        page: 1,
      );
      state = state.copyWith(
        stations: result.stations,
        pagination: result.pagination,
        isLoading: false,
        currentPage: 1,
      );
    } on StationServiceException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load stations',
      );
    }
  }

  /// Load station statistics.
  Future<void> loadStats() async {
    try {
      final stats = await _service.getStats();
      state = state.copyWith(stats: stats);
    } catch (_) {
      // Stats are non-critical; silently fail
    }
  }

  /// Load the next page (pagination).
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    try {
      final result = await _service.getStations(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        status: state.statusFilter,
        page: nextPage,
      );
      state = state.copyWith(
        stations: [...state.stations, ...result.stations],
        pagination: result.pagination,
        isLoadingMore: false,
        currentPage: nextPage,
      );
    } on StationServiceException catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.message,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Update search query and reload.
  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    await loadStations(refresh: true);
  }

  /// Set status filter and reload.
  Future<void> filterByStatus(String? status) async {
    if (status == null) {
      state = state.copyWith(clearStatusFilter: true);
    } else {
      state = state.copyWith(statusFilter: status);
    }
    await loadStations(refresh: true);
  }

  /// Create a new station and refresh the list.
  Future<Station?> createStation(CreateStationRequest request) async {
    try {
      final station = await _service.createStation(request);
      await loadStations(refresh: true);
      await loadStats();
      return station;
    } on StationServiceException catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(error: 'Failed to create station');
      return null;
    }
  }

  /// Update an existing station and refresh.
  Future<Station?> updateStation(
      String id, UpdateStationRequest request) async {
    try {
      final station = await _service.updateStation(id, request);
      // Update in-place for instant UI feedback
      final updated = state.stations
          .map((s) => s.id == id ? station : s)
          .toList();
      state = state.copyWith(stations: updated);
      await loadStats();
      return station;
    } on StationServiceException catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(error: 'Failed to update station');
      return null;
    }
  }

  /// Delete a station and refresh.
  Future<bool> deleteStation(String id, {bool force = false}) async {
    try {
      await _service.deleteStation(id, force: force);
      final updated = state.stations.where((s) => s.id != id).toList();
      state = state.copyWith(stations: updated);
      await loadStats();
      return true;
    } on StationServiceException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Failed to delete station');
      return false;
    }
  }

  /// Clear error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for [StationsService].
final stationsServiceProvider =
    Provider<StationsService>((ref) => StationsService());

/// Provider for [StationsNotifier] and [StationsState].
final stationsProvider =
    StateNotifierProvider<StationsNotifier, StationsState>((ref) {
  return StationsNotifier(ref.watch(stationsServiceProvider));
});
