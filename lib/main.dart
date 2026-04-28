/// Krizot App — Entry Point
///
/// Initialises Firebase (Core + App Check), the API client, and wraps the
/// app in a [ProviderScope] so all Riverpod providers are available
/// throughout the widget tree.
library;

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/api_client.dart';

/// reCAPTCHA v3 site key for Web App Check.
/// Pass at build/run time:
///   flutter run --dart-define=KRIZOT_RECAPTCHA_SITE_KEY=...
const String _recaptchaSiteKey = String.fromEnvironment(
  'KRIZOT_RECAPTCHA_SITE_KEY',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
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

  // Initialise the Dio-based API client (sets up interceptors, base URL, etc.)
  ApiClient.instance.init();

  runApp(
    // ProviderScope is required at the root for flutter_riverpod
    const ProviderScope(
      child: KrizotApp(),
    ),
  );
}
