/// Riverpod providers for schedule state management.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/schedule.dart';
import '../models/api_response.dart';
import '../services/schedule_service.dart';

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
    final currentParams = state.valueOrNull?.params ?? const ScheduleListParams();
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _fetchSchedules(currentParams));
  }

  /// Filter schedules by station.
  Future<void> filterByStation(String? stationId) async {
    final currentParams = state.valueOrNull?.params ?? const ScheduleListParams();
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
    final currentParams = state.valueOrNull?.params ?? const ScheduleListParams();
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
    final current = state.valueOrNull;
    if (current != null) {
      final updatedList = current.schedules.map((s) => s.id == id ? schedule : s).toList();
      state = AsyncValue.data(current.copyWith(schedules: updatedList));
    }
    return schedule;
  }

  /// Delete a schedule.
  Future<void> deleteSchedule(String id) async {
    await _service.deleteSchedule(id);
    final current = state.valueOrNull;
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
    final current = state.valueOrNull;
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
  return ref.watch(schedulesNotifierProvider).valueOrNull?.schedules ?? [];
});

/// Provider for schedule aggregate stats.
final scheduleStatsProvider = FutureProvider.family<ScheduleStats, String?>((ref, date) async {
  final service = ref.read(scheduleServiceProvider);
  return service.getStats(date: date);
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
