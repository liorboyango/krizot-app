import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import '../app_config/service_locator.dart';
import '../entities/app_user.dart';
import '../entities/cert_requirement.dart';
import '../entities/certification.dart';
import '../entities/training_session.dart';
import '../services/training_service.dart';
import '../utils/time_util.dart';
import 'availability_manager.dart';
import 'shifts_manager.dart';
import 'stations_manager.dart';

/// Training sessions: certified staff bringing uncertified trainees toward a
/// certification. Sessions live on the scheduler grid next to station shifts;
/// their priority defaults to the certification's level (higher level =
/// higher priority) but stays editable per session.
class TrainingManager {
  final _log = Logger('TrainingManager');
  final _trainingService = locator<TrainingService>();

  /// All sessions of the scheduler's selected week (manager roles only).
  final _weekSessions = BehaviorSubject<List<TrainingSession>>();
  Stream<List<TrainingSession>> get weekSessionsStream =>
      _weekSessions.stream;
  List<TrainingSession> get weekSessions =>
      _weekSessions.valueOrNull ?? const [];

  /// Sessions the signed-in user participates in (trainee or trainer).
  final _mySessions = BehaviorSubject<List<TrainingSession>>();
  Stream<List<TrainingSession>> get mySessionsStream => _mySessions.stream;
  List<TrainingSession> get mySessions => _mySessions.valueOrNull ?? const [];

  StreamSubscription? _weekSessionsListener;
  StreamSubscription? _mySessionsListener;
  StreamSubscription? _selectedDateListener;

  AppUser? _currentUser;

  Future<void> initListeners(AppUser user) async {
    const METHOD = 'initListeners';
    _log.info('$METHOD - START - role: ${user.role.name}');
    await cancelListeners();
    _currentUser = user;

    _mySessionsListener = _trainingService
        .listenToUserSessions(user.id, TimeUtil.startOfDay(DateTime.now()))
        .listen(
          (sessions) => _mySessions.sink.add(sessions),
          onError: (Object e) => _log.severe('$METHOD - mySessions: $e'),
        );

    if (user.role.canManage) {
      _selectedDateListener = locator<ShiftsManager>()
          .selectedDateStream
          .map(TimeUtil.startOfWeek)
          .distinct()
          .listen(_listenToWeek);
    }
  }

  void _listenToWeek(DateTime monday) {
    const METHOD = '_listenToWeek';
    _log.info('$METHOD - week of $monday');
    _weekSessionsListener?.cancel();
    _weekSessionsListener = _trainingService
        .listenToSessionsForRange(monday, monday.add(const Duration(days: 7)))
        .listen(
          (sessions) => _weekSessions.sink.add(sessions),
          onError: (Object e) => _log.severe('$METHOD - Error: $e'),
        );
  }

  Future<void> cancelListeners() async {
    await _weekSessionsListener?.cancel();
    await _mySessionsListener?.cancel();
    await _selectedDateListener?.cancel();
    _weekSessionsListener = null;
    _mySessionsListener = null;
    _selectedDateListener = null;
    _currentUser = null;
  }

  /// Sessions overlapping [day], highest priority first.
  List<TrainingSession> sessionsForDay(DateTime day) {
    final dayEnd = day.add(const Duration(days: 1));
    return weekSessions.where((s) => s.overlaps(day, dayEnd)).toList()
      ..sort((a, b) {
        final byPriority = b.priority.compareTo(a.priority);
        return byPriority != 0 ? byPriority : a.start.compareTo(b.start);
      });
  }

  /// Whether [userId] is tied up in a session overlapping the range —
  /// used by shift eligibility (and by trainer/trainee pickers).
  bool hasTrainingOverlap(String userId, DateTime start, DateTime end,
          {String? excludeSessionId}) =>
      weekSessions.any((s) =>
          s.id != excludeSessionId &&
          s.involves(userId) &&
          s.overlaps(start, end));

  /// Default priority for a session toward [certificationId]: the
  /// certification's level (higher level = higher priority).
  int defaultPriorityFor(String certificationId) =>
      locator<StationsManager>().certificationById(certificationId)?.level ??
      0;

  /// The staffing a session needs: simulations use the certification's own
  /// definition; spectation and tutoring need exactly one holder of the
  /// certification being trained.
  List<CertRequirement> requiredStaff(
      Certification certification, TrainingType type) {
    if (type == TrainingType.simulation &&
        certification.simulationStaff.isNotEmpty) {
      return certification.simulationStaff;
    }
    return [CertRequirement(certificationId: certification.id, count: 1)];
  }

  /// Whether [trainers] satisfy the session's staffing definition.
  bool trainersSatisfy(Certification certification, TrainingType type,
      List<AppUser> trainers) {
    if (type.isOneOnOne) {
      return trainers.length == 1 &&
          trainers.first.certifications.contains(certification.id);
    }
    for (final requirement in requiredStaff(certification, type)) {
      final holders = trainers
          .where((t) => t.certifications.contains(requirement.certificationId))
          .length;
      if (holders < requirement.count) return false;
    }
    return true;
  }

  /// Employees not yet holding the certification — potential trainees.
  List<AppUser> uncertifiedCandidates(String certificationId) =>
      locator<ShiftsManager>()
          .employees
          .where((u) => !u.certifications.contains(certificationId))
          .toList();

  /// Whether [user] can take part in a session: available status, on-site
  /// per the availability calendar, and free of shifts/other sessions.
  bool isFreeForSession(AppUser user, TrainingSession session) {
    if (!user.isAvailable) return false;
    if (!locator<AvailabilityManager>()
        .isUserPresentDuring(user.id, session.start, session.end)) {
      return false;
    }
    final hasShift = locator<ShiftsManager>().weekShifts.any((shift) =>
        shift.userId == user.id && shift.overlaps(session.start, session.end));
    if (hasShift) return false;
    return !hasTrainingOverlap(user.id, session.start, session.end,
        excludeSessionId: session.id);
  }

  Future<String?> createSession(TrainingSession session) async {
    final uid = _currentUser?.id;
    if (uid == null) return null;
    return _trainingService.createSession(session, uid);
  }

  Future<bool> updateSession(
      String sessionId, Map<String, dynamic> fields) async {
    final uid = _currentUser?.id;
    if (uid == null) return false;
    return _trainingService.updateSession(sessionId, fields, uid);
  }

  Future<bool> deleteSession(String sessionId) =>
      _trainingService.deleteSession(sessionId);

  Future<void> dispose() async {
    await cancelListeners();
    await Future.wait([_weekSessions.close(), _mySessions.close()]);
  }
}
