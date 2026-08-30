import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import '../app_config/service_locator.dart';
import '../entities/app_user.dart';
import '../entities/day_requirement.dart';
import '../entities/shift.dart';
import '../entities/station.dart';
import '../services/day_requirements_service.dart';
import '../services/shifts_service.dart';
import '../services/user_service.dart';
import '../utils/time_util.dart';
import 'availability_manager.dart';
import 'training_manager.dart';

/// Heart of Interfaces 1 & 2: the manager grid (week of shifts around a
/// selected date), the employee's own shift list, and assignment commands.
class ShiftsManager {
  final _log = Logger('ShiftsManager');
  final _shiftsService = locator<ShiftsService>();
  final _dayRequirementsService = locator<DayRequirementsService>();

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

  /// Per-day manning definitions (which certifications, how many) of the
  /// week containing [selectedDate].
  final _weekRequirements = BehaviorSubject<List<DayRequirement>>();
  Stream<List<DayRequirement>> get weekRequirementsStream =>
      _weekRequirements.stream;
  List<DayRequirement> get weekRequirements =>
      _weekRequirements.valueOrNull ?? const [];

  StreamSubscription? _weekShiftsListener;
  StreamSubscription? _weekRequirementsListener;
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
    _weekRequirementsListener?.cancel();
    _weekRequirementsListener = _dayRequirementsService
        .listenToRange(TimeUtil.dayKey(monday),
            TimeUtil.dayKey(monday.add(const Duration(days: 7))))
        .listen(
          (requirements) => _weekRequirements.sink.add(requirements),
          onError: (Object e) => _log.severe('$METHOD - requirements: $e'),
        );
  }

  Future<void> cancelListeners() async {
    await _weekShiftsListener?.cancel();
    await _weekRequirementsListener?.cancel();
    await _myShiftsListener?.cancel();
    await _employeesListener?.cancel();
    await _selectedDateListener?.cancel();
    _weekShiftsListener = null;
    _weekRequirementsListener = null;
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

  void nextDay() => selectDate(selectedDate.add(const Duration(days: 1)));

  void previousDay() =>
      selectDate(selectedDate.subtract(const Duration(days: 1)));

  /// Client-side mirror of the backend plan_validator predicate: in the
  /// station's org scope, certified for the station, available, on-site per
  /// the availability calendar, and free of overlapping shifts and training
  /// sessions.
  bool isEligible(AppUser candidate, Station station, Shift shift) {
    if (!candidate.isAvailable) return false;
    if (!candidate.matchesScope(
        site: station.site,
        department: station.department,
        jobRole: station.jobRole)) {
      return false;
    }
    if (!candidate.hasAllCertifications(station.requiredCertifications)) {
      return false;
    }
    if (!locator<AvailabilityManager>()
        .isUserPresentDuring(candidate.id, shift.start, shift.end)) {
      return false;
    }
    if (locator<TrainingManager>()
        .hasTrainingOverlap(candidate.id, shift.start, shift.end)) {
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

  /// The manning definition for [day], if one has been set.
  DayRequirement? requirementForDay(DateTime day) {
    final key = TimeUtil.dayKey(day);
    for (final requirement in weekRequirements) {
      if (requirement.dayKey == key) return requirement;
    }
    return null;
  }

  /// Coverage of [certificationId] on [day]: how many DISTINCT users
  /// assigned to shifts that day hold the certification.
  int certCoverageForDay(String certificationId, DateTime day) {
    final assignedIds = weekShifts
        .where((s) => s.isAssigned && TimeUtil.isSameDay(s.start, day))
        .map((s) => s.userId!)
        .toSet();
    return employees
        .where((u) =>
            assignedIds.contains(u.id) &&
            u.certifications.contains(certificationId))
        .length;
  }

  Future<bool> setDayRequirement(DayRequirement requirement) async {
    final uid = _currentUser?.id;
    if (uid == null) return false;
    return _dayRequirementsService.setDayRequirement(requirement, uid);
  }

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
      _weekRequirements.close(),
      _myShifts.close(),
      _employees.close(),
    ]);
  }
}
