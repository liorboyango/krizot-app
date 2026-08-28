/// Krizot — entry point.
///
/// Boot order: Firebase Core → App Check → logging → (optional) emulator
/// wiring → GetIt singletons (services + managers) → runApp.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'app_config/constants.dart';
import 'app_config/service_locator.dart';
import 'firebase_options.dart';
import 'widgets/app.dart';

/// reCAPTCHA v3 site key for Web App Check:
///   flutter run --dart-define=KRIZOT_RECAPTCHA_SITE_KEY=...
const String _recaptchaSiteKey =
    String.fromEnvironment('KRIZOT_RECAPTCHA_SITE_KEY');

/// Point Firebase at the local emulator suite:
///   flutter run --dart-define=USE_FIREBASE_EMULATOR=true
const bool _useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseApp = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    providerWeb: ReCaptchaV3Provider(_recaptchaSiteKey),
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleDeviceCheckProvider(),
  );

  _initLogger();

  if (_useEmulator) {
    _connectToEmulators(firebaseApp);
  }

  await initSingletons(firebaseApp: firebaseApp);

  runApp(const KrizotApp());
}

void _initLogger() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name} ${record.loggerName}: ${record.message}');
  });
}

void _connectToEmulators(FirebaseApp firebaseApp) {
  // Android emulators reach the host machine via 10.0.2.2.
  final host = defaultTargetPlatform == TargetPlatform.android && !kIsWeb
      ? '10.0.2.2'
      : 'localhost';
  FirebaseAuth.instance.useAuthEmulator(host, Constants.EMULATOR_AUTH_PORT);
  FirebaseFirestore.instanceFor(
    app: firebaseApp,
    databaseId: Constants.FIRESTORE_DATABASE_ID,
  ).useFirestoreEmulator(host, Constants.EMULATOR_FIRESTORE_PORT);
  FirebaseFunctions.instanceFor(
    app: firebaseApp,
    region: Constants.FUNCTIONS_REGION,
  ).useFunctionsEmulator(host, Constants.EMULATOR_FUNCTIONS_PORT);
}
