import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import '../app_config/service_locator.dart';
import '../entities/app_user.dart';
import '../entities/availability_window.dart';
import '../entities/shift.dart';
import '../entities/training_session.dart';
import '../services/availability_service.dart';
import '../services/shifts_service.dart';
import '../services/training_service.dart';
import '../utils/time_util.dart';

/// Reporting for the Statistics screen (manager roles only): per-user weekly
/// station time, monthly training totals, and availability coverage. Keeps
/// its own week/month anchors so browsing reports never moves the scheduler
/// grid, and reuses the plain range queries of the underlying services.
class StatisticsManager {
  final _log = Logger('StatisticsManager');
  final _shiftsService = locator<ShiftsService>();
  final _availabilityService = locator<AvailabilityService>();
  final _trainingService = locator<TrainingService>();

  /// Monday of the week the weekly reports cover.
  final _weekStart =
      BehaviorSubject<DateTime>.seeded(TimeUtil.startOfWeek(DateTime.now()));
  Stream<DateTime> get weekStartStream => _weekStart.stream;
  DateTime get weekStart => _weekStart.value;

  /// First day of the month the training report covers.
  final _monthStart =
      BehaviorSubject<DateTime>.seeded(TimeUtil.startOfMonth(DateTime.now()));
  Stream<DateTime> get monthStartStream => _monthStart.stream;
  DateTime get monthStart => _monthStart.value;

  /// All shifts of the report week.
  final _weekShifts = BehaviorSubject<List<Shift>>();
  Stream<List<Shift>> get weekShiftsStream => _weekShifts.stream;
  List<Shift> get weekShifts => _weekShifts.valueOrNull ?? const [];

  /// All presence windows overlapping the report week.
  final _weekWindows = BehaviorSubject<List<AvailabilityWindow>>();
  Stream<List<AvailabilityWindow>> get weekWindowsStream =>
      _weekWindows.stream;
  List<AvailabilityWindow> get weekWindows =>
      _weekWindows.valueOrNull ?? const [];

  /// All training sessions of the report month.
  final _monthSessions = BehaviorSubject<List<TrainingSession>>();
  Stream<List<TrainingSession>> get monthSessionsStream =>
      _monthSessions.stream;
  List<TrainingSession> get monthSessions =>
      _monthSessions.valueOrNull ?? const [];

  StreamSubscription? _weekStartListener;
  StreamSubscription? _monthStartListener;
  StreamSubscription? _weekShiftsListener;
  StreamSubscription? _weekWindowsListener;
  StreamSubscription? _monthSessionsListener;

  Future<void> initListeners(AppUser user) async {
    const METHOD = 'initListeners';
    _log.info('$METHOD - START - role: ${user.role.name}');
    await cancelListeners();
    if (!user.role.canManage) return;

    _weekStartListener = _weekStart.distinct().listen(_listenToWeek);
    _monthStartListener = _monthStart.distinct().listen(_listenToMonth);
  }

  void _listenToWeek(DateTime monday) {
    const METHOD = '_listenToWeek';
    _log.info('$METHOD - week of $monday');
    final weekEnd = monday.add(const Duration(days: 7));
    _weekShiftsListener?.cancel();
    _weekShiftsListener =
        _shiftsService.listenToShiftsForRange(monday, weekEnd).listen(
              (shifts) => _weekShifts.sink.add(shifts),
              onError: (Object e) => _log.severe('$METHOD - shifts: $e'),
            );
    _weekWindowsListener?.cancel();
    _weekWindowsListener =
        _availabilityService.listenToWindowsForRange(monday, weekEnd).listen(
              (windows) => _weekWindows.sink.add(windows),
              onError: (Object e) => _log.severe('$METHOD - windows: $e'),
            );
  }

  void _listenToMonth(DateTime monthStart) {
    const METHOD = '_listenToMonth';
    _log.info('$METHOD - month of $monthStart');
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1);
    _monthSessionsListener?.cancel();
    _monthSessionsListener =
        _trainingService.listenToSessionsForRange(monthStart, monthEnd).listen(
              (sessions) => _monthSessions.sink.add(sessions),
              onError: (Object e) => _log.severe('$METHOD - sessions: $e'),
            );
  }

  Future<void> cancelListeners() async {
    await _weekStartListener?.cancel();
    await _monthStartListener?.cancel();
    await _weekShiftsListener?.cancel();
    await _weekWindowsListener?.cancel();
    await _monthSessionsListener?.cancel();
    _weekStartListener = null;
    _monthStartListener = null;
    _weekShiftsListener = null;
    _weekWindowsListener = null;
    _monthSessionsListener = null;
  }

  void previousWeek() =>
      _weekStart.sink.add(weekStart.subtract(const Duration(days: 7)));

  void nextWeek() => _weekStart.sink.add(weekStart.add(const Duration(days: 7)));

  void previousMonth() => _monthStart.sink
      .add(DateTime(monthStart.year, monthStart.month - 1));

  void nextMonth() =>
      _monthStart.sink.add(DateTime(monthStart.year, monthStart.month + 1));

  /// Total assigned station time per user.
  static Map<String, Duration> stationTimeByUser(List<Shift> shifts) {
    final totals = <String, Duration>{};
    for (final shift in shifts) {
      final userId = shift.userId;
      if (userId == null) continue;
      totals[userId] = (totals[userId] ?? Duration.zero) + shift.duration;
    }
    return totals;
  }

  /// Number of assigned shifts per user.
  static Map<String, int> shiftCountByUser(List<Shift> shifts) {
    final counts = <String, int>{};
    for (final shift in shifts) {
      final userId = shift.userId;
      if (userId == null) continue;
      counts[userId] = (counts[userId] ?? 0) + 1;
    }
    return counts;
  }

  /// Time each user spends in training, as trainee or trainer.
  static Map<String, Duration> trainingTimeByUser(
      List<TrainingSession> sessions) {
    final totals = <String, Duration>{};
    for (final session in sessions) {
      for (final userId in {
        if (session.traineeId != null) session.traineeId!,
        ...session.trainerIds,
      }) {
        totals[userId] = (totals[userId] ?? Duration.zero) + session.duration;
      }
    }
    return totals;
  }

  /// Number of sessions each user participates in.
  static Map<String, int> sessionCountByUser(List<TrainingSession> sessions) {
    final counts = <String, int>{};
    for (final session in sessions) {
      for (final userId in {
        if (session.traineeId != null) session.traineeId!,
        ...session.trainerIds,
      }) {
        counts[userId] = (counts[userId] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// On-site time per user inside [rangeStart, rangeEnd): each user's
  /// windows are clipped to the range and merged first, so overlapping
  /// windows never double-count. A user without windows is absent here —
  /// per the legacy semantics the UI shows them as always-present instead.
  static Map<String, Duration> presenceByUser(
    List<AvailabilityWindow> windows,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final byUser = <String, List<AvailabilityWindow>>{};
    for (final window in windows) {
      byUser.putIfAbsent(window.userId, () => []).add(window);
    }
    final totals = <String, Duration>{};
    byUser.forEach((userId, userWindows) {
      final clipped = userWindows
          .map((w) => (
                start: w.start.isAfter(rangeStart) ? w.start : rangeStart,
                end: w.end.isBefore(rangeEnd) ? w.end : rangeEnd,
              ))
          .where((w) => w.start.isBefore(w.end))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      var total = Duration.zero;
      DateTime? mergedEnd;
      for (final window in clipped) {
        final start = mergedEnd != null && window.start.isBefore(mergedEnd)
            ? mergedEnd
            : window.start;
        if (window.end.isAfter(start)) {
          total += window.end.difference(start);
          mergedEnd = window.end;
        }
      }
      totals[userId] = total;
    });
    return totals;
  }

  Future<void> dispose() async {
    await cancelListeners();
    await Future.wait([
      _weekStart.close(),
      _monthStart.close(),
      _weekShifts.close(),
      _weekWindows.close(),
      _monthSessions.close(),
    ]);
  }
}
