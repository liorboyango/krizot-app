import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Schedule view mode
// ---------------------------------------------------------------------------
enum ScheduleViewMode { week, day, list }

// ---------------------------------------------------------------------------
// Selected week provider
// ---------------------------------------------------------------------------
final selectedWeekProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  // Start of current week (Monday)
  final weekday = now.weekday; // 1=Mon, 7=Sun
  return now.subtract(Duration(days: weekday - 1));
});

// ---------------------------------------------------------------------------
// View mode provider
// ---------------------------------------------------------------------------
final scheduleViewModeProvider =
    StateProvider<ScheduleViewMode>((ref) => ScheduleViewMode.week);

// ---------------------------------------------------------------------------
// Selected day provider (for day view)
// ---------------------------------------------------------------------------
final selectedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());

// ---------------------------------------------------------------------------
// Schedule service provider
// ---------------------------------------------------------------------------
final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  final dio = ref.watch(dioProvider);
  return ScheduleService(dio);
});

// ---------------------------------------------------------------------------
// Weekly schedule provider
// ---------------------------------------------------------------------------
final weeklyScheduleProvider =
    FutureProvider.autoDispose<WeeklySchedule>((ref) async {
  final service = ref.watch(scheduleServiceProvider);
  final weekStart = ref.watch(selectedWeekProvider);
  return service.getWeeklySchedule(weekStart);
});

// ---------------------------------------------------------------------------
// Schedule stats provider
// ---------------------------------------------------------------------------
final scheduleStatsProvider =
    FutureProvider.autoDispose<ScheduleStats>((ref) async {
  final service = ref.watch(scheduleServiceProvider);
  return service.getStats();
});

// ---------------------------------------------------------------------------
// Schedules list provider (for list view)
// ---------------------------------------------------------------------------
class SchedulesListState {
  final List<Schedule> schedules;
  final bool isLoading;
  final String? error;
  final int page;
  final int totalPages;

  const SchedulesListState({
    this.schedules = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.totalPages = 1,
  });

  SchedulesListState copyWith({
    List<Schedule>? schedules,
    bool? isLoading,
    String? error,
    int? page,
    int? totalPages,
  }) {
    return SchedulesListState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class SchedulesListNotifier extends StateNotifier<SchedulesListState> {
  final ScheduleService _service;

  SchedulesListNotifier(this._service) : super(const SchedulesListState()) {
    loadSchedules();
  }

  Future<void> loadSchedules({
    String? stationId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.getSchedules(
        stationId: stationId,
        startDate: startDate,
        endDate: endDate,
        page: page,
      );
      final pagination = result['pagination'] as Map<String, dynamic>?;
      state = state.copyWith(
        schedules: result['schedules'] as List<Schedule>,
        isLoading: false,
        page: pagination?['page'] as int? ?? 1,
        totalPages: pagination?['totalPages'] as int? ?? 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> createSchedule({
    required String stationId,
    String? userId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    await _service.createSchedule(
      stationId: stationId,
      userId: userId,
      startTime: startTime,
      endTime: endTime,
      notes: notes,
    );
    await loadSchedules();
  }

  Future<void> deleteSchedule(String id) async {
    await _service.deleteSchedule(id);
    state = state.copyWith(
      schedules: state.schedules.where((s) => s.id != id).toList(),
    );
  }

  Future<Schedule> assignUser(String scheduleId, String userId) async {
    final result = await _service.assignSchedules([
      {'scheduleId': scheduleId, 'userId': userId},
    ]);
    await loadSchedules();
    // Return updated schedule from succeeded list if available
    final succeeded = result['succeeded'] as List<dynamic>?;
    if (succeeded != null && succeeded.isNotEmpty) {
      return Schedule.fromJson(succeeded.first as Map<String, dynamic>);
    }
    throw Exception('Assignment failed');
  }

  Future<void> unassignUser(String scheduleId) async {
    await _service.unassignSchedule(scheduleId);
    await loadSchedules();
  }
}

final schedulesListProvider =
    StateNotifierProvider.autoDispose<SchedulesListNotifier, SchedulesListState>(
  (ref) {
    final service = ref.watch(scheduleServiceProvider);
    return SchedulesListNotifier(service);
  },
);

// ---------------------------------------------------------------------------
// Assignment panel state
// ---------------------------------------------------------------------------
class AssignmentPanelState {
  final bool isOpen;
  final Schedule? selectedSchedule;
  final bool isAssigning;
  final String? error;

  const AssignmentPanelState({
    this.isOpen = false,
    this.selectedSchedule,
    this.isAssigning = false,
    this.error,
  });

  AssignmentPanelState copyWith({
    bool? isOpen,
    Schedule? selectedSchedule,
    bool? isAssigning,
    String? error,
  }) {
    return AssignmentPanelState(
      isOpen: isOpen ?? this.isOpen,
      selectedSchedule: selectedSchedule ?? this.selectedSchedule,
      isAssigning: isAssigning ?? this.isAssigning,
      error: error,
    );
  }
}

class AssignmentPanelNotifier extends StateNotifier<AssignmentPanelState> {
  AssignmentPanelNotifier() : super(const AssignmentPanelState());

  void open(Schedule schedule) {
    state = AssignmentPanelState(isOpen: true, selectedSchedule: schedule);
  }

  void close() {
    state = const AssignmentPanelState();
  }

  void setAssigning(bool value) {
    state = state.copyWith(isAssigning: value);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

final assignmentPanelProvider =
    StateNotifierProvider<AssignmentPanelNotifier, AssignmentPanelState>(
  (ref) => AssignmentPanelNotifier(),
);
