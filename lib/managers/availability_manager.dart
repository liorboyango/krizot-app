import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import '../app_config/service_locator.dart';
import '../entities/app_user.dart';
import '../entities/availability_window.dart';
import '../services/availability_service.dart';
import '../utils/time_util.dart';
import 'shifts_manager.dart';

/// The per-hour availability calendar: each user records presence windows
/// (arriving 13.9 12:00 → leaving 15.9 15:00). Managers see the whole
/// staff's windows for the scheduler week; employees manage their own.
class AvailabilityManager {
  final _log = Logger('AvailabilityManager');
  final _availabilityService = locator<AvailabilityService>();

  /// All staff windows overlapping the scheduler's selected week
  /// (manager roles only).
  final _weekWindows = BehaviorSubject<List<AvailabilityWindow>>();
  Stream<List<AvailabilityWindow>> get weekWindowsStream =>
      _weekWindows.stream;
  List<AvailabilityWindow> get weekWindows =>
      _weekWindows.valueOrNull ?? const [];

  /// The signed-in user's own upcoming windows (employee calendar).
  final _myWindows = BehaviorSubject<List<AvailabilityWindow>>();
  Stream<List<AvailabilityWindow>> get myWindowsStream => _myWindows.stream;
  List<AvailabilityWindow> get myWindows => _myWindows.valueOrNull ?? const [];

  StreamSubscription? _weekWindowsListener;
  StreamSubscription? _myWindowsListener;
  StreamSubscription? _selectedDateListener;

  AppUser? _currentUser;

  Future<void> initListeners(AppUser user) async {
    const METHOD = 'initListeners';
    _log.info('$METHOD - START - role: ${user.role.name}');
    await cancelListeners();
    _currentUser = user;

    _myWindowsListener = _availabilityService
        .listenToUserWindows(user.id, TimeUtil.startOfDay(DateTime.now()))
        .listen(
          (windows) => _myWindows.sink.add(windows),
          onError: (Object e) => _log.severe('$METHOD - myWindows: $e'),
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
    _weekWindowsListener?.cancel();
    _weekWindowsListener = _availabilityService
        .listenToWindowsForRange(monday, monday.add(const Duration(days: 7)))
        .listen(
          (windows) => _weekWindows.sink.add(windows),
          onError: (Object e) => _log.severe('$METHOD - Error: $e'),
        );
  }

  Future<void> cancelListeners() async {
    await _weekWindowsListener?.cancel();
    await _myWindowsListener?.cancel();
    await _selectedDateListener?.cancel();
    _weekWindowsListener = null;
    _myWindowsListener = null;
    _selectedDateListener = null;
    _currentUser = null;
  }

  List<AvailabilityWindow> windowsForUser(String userId) =>
      weekWindows.where((w) => w.userId == userId).toList();

  /// One user's windows ending after [from] — live feed for the per-user
  /// availability calendar dialog (not bounded to the scheduler week).
  Stream<List<AvailabilityWindow>> userWindowsStream(
          String userId, DateTime from) =>
      _availabilityService.listenToUserWindows(userId, from);

  /// Whether [userId] is on-site for the whole [start, end) range.
  /// A user with no window overlapping the loaded week is treated as
  /// always-present (legacy users without a calendar).
  bool isUserPresentDuring(String userId, DateTime start, DateTime end) {
    final windows = windowsForUser(userId);
    if (windows.isEmpty) return true;
    return windows.any((w) => w.covers(start, end));
  }

  /// The user's presence windows intersecting [day] — roster indicator.
  List<AvailabilityWindow> windowsForUserDay(String userId, DateTime day) {
    final dayEnd = day.add(const Duration(days: 1));
    return windowsForUser(userId)
        .where((w) => w.overlaps(day, dayEnd))
        .toList();
  }

  Future<String?> createMyWindow(DateTime start, DateTime end) async {
    final uid = _currentUser?.id;
    if (uid == null) return null;
    return _availabilityService.createWindow(AvailabilityWindow(
      id: '',
      userId: uid,
      start: start,
      end: end,
    ));
  }

  /// Manager action from the scheduler — record a window for any user.
  Future<String?> createWindowFor(
          String userId, DateTime start, DateTime end) =>
      _availabilityService.createWindow(AvailabilityWindow(
        id: '',
        userId: userId,
        start: start,
        end: end,
      ));

  Future<bool> updateWindow(String windowId, DateTime start, DateTime end) =>
      _availabilityService.updateWindow(windowId, start, end);

  Future<bool> deleteWindow(String windowId) =>
      _availabilityService.deleteWindow(windowId);

  Future<void> dispose() async {
    await cancelListeners();
    await Future.wait([_weekWindows.close(), _myWindows.close()]);
  }
}
