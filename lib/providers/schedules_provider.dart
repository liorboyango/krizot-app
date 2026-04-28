/// Riverpod providers for schedule state management.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/schedule.dart';
import '../models/station.dart';
import '../models/api_response.dart';
import '../services/schedule_service.dart';
import '../services/station_service.dart';
import 'stations_provider.dart';

// Service provider
final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService();
});

/// Holds the current schedule list query parameters and data.
class ScheduleListState {
  const ScheduleListState({
    this.params = const ScheduleListParams(),
    this.schedules = const [],
    this.pagination,
    this.isLoading = false,
    this.error,
  });

  final ScheduleListParams params;
  final List<Schedule> schedules;
  final Pagination? pagination;
  final bool isLoading;
  final String? error;

  ScheduleListState copyWith({
    ScheduleListParams? params,
    List<Schedule>? schedules,
    Pagination? pagination,
    bool? isLoading,
    String? error,
  }) {
    return ScheduleListState(
      params: params ?? this.params,
      schedules: schedules ?? this.schedules,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Manages the schedule list with CRUD operations.
class SchedulesNotifier extends AsyncNotifier<ScheduleListState> {
  late ScheduleService _service;

  @override
  Future<ScheduleListState> build() async {
    _service = ref.read(scheduleServiceProvider);
    return _fetchSchedules(const ScheduleListParams());
  }

  Future<ScheduleListState> _fetchSchedules(ScheduleListParams params) async {
    try {
      final result = await _service.getSchedules(params);
      return ScheduleListState(
        params: params,
        schedules: result.data,
        pagination: result.pagination,
        isLoading: false,
      );
    } on ApiException catch (e) {
      return ScheduleListState(params: params, error: e.userMessage);
    } on NetworkException catch (e) {
      return ScheduleListState(params: params, error: e.message);
    }
  }

  /// Reload the schedule list with the current parameters.
  Future<void> refresh() async {
    final currentParams = state.value?.params ?? const ScheduleListParams();
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _fetchSchedules(currentParams));
  }

  /// Filter schedules by station.
  Future<void> filterByStation(String? stationId) async {
    final currentParams = state.value?.params ?? const ScheduleListParams();
    final newParams = ScheduleListParams(
      page: 1,
      limit: currentParams.limit,
      stationId: stationId,
      userId: currentParams.userId,
      startDate: currentParams.startDate,
      endDate: currentParams.endDate,
    );
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _fetchSchedules(newParams));
  }

  /// Filter schedules by date range.
  Future<void> filterByDateRange(DateTime start, DateTime end) async {
    final currentParams = state.value?.params ?? const ScheduleListParams();
    final newParams = ScheduleListParams(
      page: 1,
      limit: currentParams.limit,
      stationId: currentParams.stationId,
      userId: currentParams.userId,
      startDate: start,
      endDate: end,
    );
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _fetchSchedules(newParams));
  }

  /// Create a new schedule and refresh the list.
  Future<Schedule> createSchedule(CreateScheduleRequest request) async {
    final schedule = await _service.createSchedule(request);
    await refresh();
    return schedule;
  }

  /// Update an existing schedule.
  Future<Schedule> updateSchedule(String id, UpdateScheduleRequest request) async {
    final schedule = await _service.updateSchedule(id, request);
    final current = state.value;
    if (current != null) {
      final updatedList = current.schedules.map((s) => s.id == id ? schedule : s).toList();
      state = AsyncValue.data(current.copyWith(schedules: updatedList));
    }
    return schedule;
  }

  /// Delete a schedule.
  Future<void> deleteSchedule(String id) async {
    await _service.deleteSchedule(id);
    final current = state.value;
    if (current != null) {
      final updatedList = current.schedules.where((s) => s.id != id).toList();
      state = AsyncValue.data(current.copyWith(schedules: updatedList));
    }
  }

  /// Bulk assign users to schedules.
  Future<BulkAssignResult> bulkAssign(List<AssignmentRequest> assignments) async {
    final result = await _service.bulkAssign(assignments);
    await refresh();
    return result;
  }

  /// Unassign a user from a schedule.
  Future<Schedule> unassign(String scheduleId) async {
    final schedule = await _service.unassign(scheduleId);
    final current = state.value;
    if (current != null) {
      final updatedList = current.schedules.map((s) => s.id == scheduleId ? schedule : s).toList();
      state = AsyncValue.data(current.copyWith(schedules: updatedList));
    }
    return schedule;
  }
}

/// Provider for the [SchedulesNotifier].
final schedulesNotifierProvider =
    AsyncNotifierProvider<SchedulesNotifier, ScheduleListState>(SchedulesNotifier.new);

/// Convenience provider for the schedule list.
final schedulesProvider = Provider<List<Schedule>>((ref) {
  return ref.watch(schedulesNotifierProvider).value?.schedules ?? [];
});

/// Provider for schedule aggregate stats, computed client-side by fetching
/// schedules for the target day and the station list (the backend has no
/// dedicated stats endpoint).
///
/// `criticalShifts` is defined here as unassigned shifts starting within
/// the next hour. Tune the threshold if the product definition changes.
final scheduleStatsProvider = FutureProvider.family<ScheduleStats, String?>((ref, date) async {
  final scheduleService = ref.read(scheduleServiceProvider);
  final stationService = ref.read(stationServiceProvider);

  final targetDate = date != null ? DateTime.parse(date) : DateTime.now();
  final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final scheduleResult = await scheduleService.getSchedules(
    ScheduleListParams(startDate: startOfDay, endDate: endOfDay, limit: 500),
  );
  final stationResult = await stationService.getStations(
    const StationListParams(limit: 100),
  );

  final schedules = scheduleResult.data;
  final stations = stationResult.data;
  final now = DateTime.now();

  var onDuty = 0;
  var openShifts = 0;
  var criticalShifts = 0;
  for (final s in schedules) {
    final isLive = !s.startTime.isAfter(now) && s.endTime.isAfter(now);
    if (isLive && s.isAssigned) onDuty++;
    if (!s.isAssigned && s.endTime.isAfter(now)) {
      openShifts++;
      final minutesUntilStart = s.startTime.difference(now).inMinutes;
      if (minutesUntilStart <= 60) criticalShifts++;
    }
  }

  final activeStations =
      stations.where((s) => s.status == StationStatus.active).length;

  return ScheduleStats(
    totalStations: stationResult.pagination.total ?? stations.length,
    onDuty: onDuty,
    openShifts: openShifts,
    criticalShifts: criticalShifts,
    activeStations: activeStations,
    date: date,
  );
});

/// Provider for the weekly schedule grid.
final weeklyScheduleProvider = FutureProvider.family<WeeklySchedule, String?>((ref, weekStart) async {
  final service = ref.read(scheduleServiceProvider);
  return service.getWeeklySchedule(weekStart: weekStart);
});

/// Provider for a single schedule by ID.
final scheduleDetailProvider = FutureProvider.family<Schedule, String>((ref, id) async {
  final service = ref.read(scheduleServiceProvider);
  return service.getSchedule(id);
});
