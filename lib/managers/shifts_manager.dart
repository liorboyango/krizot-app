import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import '../app_config/service_locator.dart';
import '../entities/app_user.dart';
import '../entities/shift.dart';
import '../entities/station.dart';
import '../services/shifts_service.dart';
import '../services/user_service.dart';
import '../utils/time_util.dart';

/// Heart of Interfaces 1 & 2: the manager grid (week of shifts around a
/// selected date), the employee's own shift list, and assignment commands.
class ShiftsManager {
  final _log = Logger('ShiftsManager');
  final _shiftsService = locator<ShiftsService>();

  /// The date the scheduler grid is focused on.
  final _selectedDate = BehaviorSubject<DateTime>.seeded(DateTime.now());
  Stream<DateTime> get selectedDateStream => _selectedDate.stream;
  DateTime get selectedDate => _selectedDate.value;

  /// All shifts of the week containing [selectedDate] (manager grid).
  final _weekShifts = BehaviorSubject<List<Shift>>();
  Stream<List<Shift>> get weekShiftsStream => _weekShifts.stream;
  List<Shift> get weekShifts => _weekShifts.valueOrNull ?? const [];

  /// The signed-in user's own upcoming/current shifts (employee view).
  final _myShifts = BehaviorSubject<List<Shift>>();
  Stream<List<Shift>> get myShiftsStream => _myShifts.stream;
  List<Shift> get myShifts => _myShifts.valueOrNull ?? const [];

  /// All employees, kept warm for the roster/assignment panels
  /// (manager roles only — employees can't read /users broadly).
  final _employees = BehaviorSubject<List<AppUser>>();
  Stream<List<AppUser>> get employeesStream => _employees.stream;
  List<AppUser> get employees => _employees.valueOrNull ?? const [];

  StreamSubscription? _weekShiftsListener;
  StreamSubscription? _myShiftsListener;
  StreamSubscription? _employeesListener;
  StreamSubscription? _selectedDateListener;

  AppUser? _currentUser;

  Shift? get currentShift {
    final now = DateTime.now();
    for (final shift in myShifts) {
      if (!shift.start.isAfter(now) && shift.end.isAfter(now)) return shift;
    }
    return null;
  }

  Shift? get nextShift {
    final now = DateTime.now();
    for (final shift in myShifts) {
      if (shift.start.isAfter(now)) return shift;
    }
    return null;
  }

  Stream<List<Shift>> shiftsForDayStream(DateTime day) => weekShiftsStream.map(
      (shifts) => shifts.where((s) => TimeUtil.isSameDay(s.start, day)).toList());

  List<Shift> shiftsForStationDay(String stationId, DateTime day) => weekShifts
      .where((s) => s.stationId == stationId && TimeUtil.isSameDay(s.start, day))
      .toList();

  /// Count of the signed-in user's schedule changes awaiting acknowledgement.
  Stream<int> get pendingAckCountStream => myShiftsStream.map(
      (shifts) => shifts.where((s) => s.isAssigned && !s.acknowledged).length);

  Future<void> initListeners(AppUser user) async {
    const METHOD = 'initListeners';
    _log.info('$METHOD - START - role: ${user.role.name}');
    await cancelListeners();
    _currentUser = user;

    _myShiftsListener = _shiftsService
        .listenToUserShifts(user.id, TimeUtil.startOfDay(DateTime.now()))
        .listen(
          (shifts) => _myShifts.sink.add(shifts),
          onError: (Object e) => _log.severe('$METHOD - myShifts: $e'),
        );

    if (user.role.canManage) {
      _selectedDateListener = _selectedDate
          .map(TimeUtil.startOfWeek)
          .distinct()
          .listen(_listenToWeek);
      _employeesListener = locator<UserService>().listenToUsers().listen(
            (users) => _employees.sink.add(users),
            onError: (Object e) => _log.severe('$METHOD - employees: $e'),
          );
    }
  }

  void _listenToWeek(DateTime monday) {
    const METHOD = '_listenToWeek';
    _log.info('$METHOD - week of $monday');
    _weekShiftsListener?.cancel();
    _weekShiftsListener = _shiftsService
        .listenToShiftsForRange(monday, monday.add(const Duration(days: 7)))
        .listen(
          (shifts) => _weekShifts.sink.add(shifts),
          onError: (Object e) => _log.severe('$METHOD - Error: $e'),
        );
  }

  Future<void> cancelListeners() async {
    await _weekShiftsListener?.cancel();
    await _myShiftsListener?.cancel();
    await _employeesListener?.cancel();
    await _selectedDateListener?.cancel();
    _weekShiftsListener = null;
    _myShiftsListener = null;
    _employeesListener = null;
    _selectedDateListener = null;
    _currentUser = null;
  }

  void selectDate(DateTime date) => _selectedDate.sink.add(date);

  void nextWeek() =>
      selectDate(selectedDate.add(const Duration(days: 7)));

  void previousWeek() =>
      selectDate(selectedDate.subtract(const Duration(days: 7)));

  /// Client-side mirror of the backend plan_validator predicate: certified
  /// for the station, available, and free of overlapping shifts that day.
  bool isEligible(AppUser candidate, Station station, Shift shift) {
    if (!candidate.isAvailable) return false;
    if (!candidate.hasAllCertifications(station.requiredCertifications)) {
      return false;
    }
    final hasOverlap = weekShifts.any((other) =>
        other.id != shift.id &&
        other.userId == candidate.id &&
        other.overlaps(shift.start, shift.end));
    return !hasOverlap;
  }

  List<AppUser> eligibleCandidates(Station station, Shift shift) =>
      employees.where((user) => isEligible(user, station, shift)).toList();

  Future<String?> createShift(Shift shift) async {
    final uid = _currentUser?.id;
    if (uid == null) return null;
    return _shiftsService.createShift(shift, uid);
  }

  Future<bool> updateShiftTimes(
      String shiftId, DateTime start, DateTime end) async {
    final uid = _currentUser?.id;
    if (uid == null) return false;
    return _shiftsService.updateShift(shiftId, {
      'start': start,
      'end': end,
      'dayKey': TimeUtil.dayKey(start),
    }, uid);
  }

  Future<bool> assignShift(String shiftId, String userId,
      {ShiftSource source = ShiftSource.manual}) async {
    final uid = _currentUser?.id;
    if (uid == null) return false;
    return _shiftsService.assignShift(shiftId, userId, uid, source: source);
  }

  Future<bool> unassignShift(String shiftId) async {
    final uid = _currentUser?.id;
    if (uid == null) return false;
    return _shiftsService.unassignShift(shiftId, uid);
  }

  Future<bool> deleteShift(String shiftId) => _shiftsService.deleteShift(shiftId);

  Future<bool> acknowledgeShift(String shiftId) =>
      _shiftsService.acknowledgeShift(shiftId);

  Future<void> dispose() async {
    await cancelListeners();
    await Future.wait([
      _selectedDate.close(),
      _weekShifts.close(),
      _myShifts.close(),
      _employees.close(),
    ]);
  }
}
