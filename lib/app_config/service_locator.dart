import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../managers/dispatch_manager.dart';
import '../managers/notifications_manager.dart';
import '../managers/shifts_manager.dart';
import '../managers/stations_manager.dart';
import '../managers/user_manager.dart';
import '../services/certifications_service.dart';
import '../services/dispatch_service.dart';
import '../services/functions_service.dart';
import '../services/shifts_service.dart';
import '../services/stations_service.dart';
import '../services/user_service.dart';
import 'constants.dart';

final locator = GetIt.instance;

/// Eager registration, ordered by dependency: Firebase handles first, then
/// each service immediately before the manager that resolves it in its
/// field initializers.
Future<void> initSingletons({
  required FirebaseApp firebaseApp,
  bool reset = false,
}) async {
  if (reset) {
    await disposeAllSingletons();
  }

  // The project uses the named Firestore database, not (default).
  locator.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instanceFor(
    app: firebaseApp,
    databaseId: Constants.FIRESTORE_DATABASE_ID,
  ));
  locator.registerSingleton<FirebaseFunctions>(FirebaseFunctions.instanceFor(
    app: firebaseApp,
    region: Constants.FUNCTIONS_REGION,
  ));

  /// Stations + certifications
  locator.registerSingleton<StationsService>(StationsService());
  locator.registerSingleton<CertificationsService>(CertificationsService());
  locator.registerSingleton<StationsManager>(
    StationsManager(),
    dispose: (manager) => manager.dispose(),
  );

  /// Shifts
  locator.registerSingleton<ShiftsService>(ShiftsService());
  locator.registerSingleton<ShiftsManager>(
    ShiftsManager(),
    dispose: (manager) => manager.dispose(),
  );

  /// Dispatch
  locator.registerSingleton<DispatchService>(DispatchService());
  locator.registerSingleton<FunctionsService>(FunctionsService());
  locator.registerSingleton<DispatchManager>(
    DispatchManager(),
    dispose: (manager) => manager.dispose(),
  );

  /// Notifications
  locator.registerSingleton<NotificationsManager>(
    NotificationsManager(),
    dispose: (manager) => manager.dispose(),
  );

  /// User — LAST: its auth listener orchestrates every manager above.
  locator.registerSingleton<UserService>(UserService());
  locator.registerSingleton<UserManager>(
    UserManager(),
    dispose: (manager) => manager.dispose(),
  );
}

void registerGoRouter(GoRouter router) {
  if (locator.isRegistered<GoRouter>()) {
    locator.unregister<GoRouter>();
  }
  locator.registerSingleton<GoRouter>(router,
      dispose: (router) => router.dispose());
}

Future<void> disposeAllSingletons() async => locator.reset(dispose: true);
