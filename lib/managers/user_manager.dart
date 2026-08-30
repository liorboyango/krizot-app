import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import '../app_config/service_locator.dart';
import '../entities/app_user.dart';
import '../managers/availability_manager.dart';
import '../managers/dispatch_manager.dart';
import '../managers/notifications_manager.dart';
import '../managers/shifts_manager.dart';
import '../managers/stations_manager.dart';
import '../managers/statistics_manager.dart';
import '../managers/training_manager.dart';
import '../services/user_service.dart';

/// Orchestrator: follows Firebase auth state, mirrors the `users/{uid}` doc,
/// keeps the role custom-claim fresh, and starts/stops every other manager's
/// listeners when the signed-in user changes.
class UserManager {
  final _log = Logger('UserManager');
  final _userService = locator<UserService>();

  /// The signed-in user's Firestore profile. Null while signed out or until
  /// the backend has created the doc on first sign-in.
  final _user = BehaviorSubject<AppUser?>();
  Stream<AppUser?> get onUserChanged => _user.stream;
  AppUser? get user => _user.valueOrNull;

  /// True once the initial auth state has been restored — the router keeps
  /// showing the splash screen until then.
  final _authResolved = BehaviorSubject<bool>.seeded(false);
  Stream<bool> get authResolvedStream => _authResolved.stream;
  bool get authResolved => _authResolved.value;

  bool get isSignedIn => _userService.currentUser != null;
  UserRole? get role => user?.role;

  StreamSubscription? _authStateListener;
  StreamSubscription? _userDocListener;
  String? _lastClaimRole;

  UserManager() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authStateListener = _userService.authStateChanges.listen((firebaseUser) {
      const METHOD = '_initAuthListener';
      _log.info('$METHOD - uid: ${firebaseUser?.uid}');
      if (firebaseUser != null) {
        _startUserDocListener(firebaseUser);
      } else {
        _stopListeners();
        _user.sink.add(null);
      }
      if (!_authResolved.value) _authResolved.sink.add(true);
    });
  }

  void _startUserDocListener(User firebaseUser) {
    _userDocListener?.cancel();
    var startedManagers = false;
    _userDocListener =
        _userService.listenToUser(firebaseUser.uid).listen((appUser) async {
      if (appUser == null) {
        // Doc not created yet — onAuthUserCreate is still running.
        _user.sink.add(null);
        return;
      }
      await _refreshRoleClaimIfStale(appUser);
      _user.sink.add(appUser);
      if (!startedManagers) {
        startedManagers = true;
        await _startManagers(appUser);
      }
    });
  }

  /// Custom-claim changes only reach security rules after a token refresh;
  /// the Firestore `role` field mirrors the claim, so a mismatch means our
  /// token is stale.
  Future<void> _refreshRoleClaimIfStale(AppUser appUser) async {
    const METHOD = '_refreshRoleClaimIfStale';
    _lastClaimRole ??= await _userService.getRoleClaim();
    if (_lastClaimRole != appUser.role.name) {
      _log.info('$METHOD - claim "$_lastClaimRole" != doc '
          '"${appUser.role.name}", forcing token refresh');
      _lastClaimRole = await _userService.getRoleClaim(forceRefresh: true);
    }
  }

  Future<void> _startManagers(AppUser appUser) async {
    const METHOD = '_startManagers';
    _log.info('$METHOD - role: ${appUser.role.name}');
    await locator<StationsManager>().initListeners(appUser.id);
    await locator<ShiftsManager>().initListeners(appUser);
    await locator<AvailabilityManager>().initListeners(appUser);
    await locator<TrainingManager>().initListeners(appUser);
    await locator<StatisticsManager>().initListeners(appUser);
    await locator<DispatchManager>().initListeners(appUser);
    await locator<NotificationsManager>().initPushNotifications(appUser.id);
  }

  void _stopListeners() {
    _userDocListener?.cancel();
    _userDocListener = null;
    _lastClaimRole = null;
    if (locator.isRegistered<StationsManager>()) {
      locator<StationsManager>().cancelListeners();
      locator<ShiftsManager>().cancelListeners();
      locator<AvailabilityManager>().cancelListeners();
      locator<TrainingManager>().cancelListeners();
      locator<StatisticsManager>().cancelListeners();
      locator<DispatchManager>().cancelListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    const METHOD = 'signInWithGoogle';
    _log.info('$METHOD - START');
    final credential = await _userService.signInWithGoogle();
    return credential != null;
  }

  Future<void> signOut() async {
    const METHOD = 'signOut';
    _log.info('$METHOD - START');
    await _userService.signOut();
  }

  Future<bool> updateMyStatus(UserStatus status) async {
    final uid = user?.id;
    if (uid == null) return false;
    return _userService.updateStatus(uid, status);
  }

  Future<void> dispose() async {
    await _authStateListener?.cancel();
    await _userDocListener?.cancel();
    await Future.wait([_user.close(), _authResolved.close()]);
  }
}
