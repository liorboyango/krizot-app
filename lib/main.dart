/// Krizot - Shift Operations Platform
/// Main entry point for the Flutter application.
///
/// This file bootstraps the app with:
/// - [ProviderScope] for Riverpod state management
/// - Error handling for uncaught Flutter and async errors
/// - The root [KrizotApp] widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // Ensure Flutter bindings are initialized before any plugin usage.
  WidgetsFlutterBinding.ensureInitialized();

  // Catch uncaught Flutter framework errors.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };

  runApp(
    // ProviderScope is the root widget that enables Riverpod throughout the tree.
    const ProviderScope(
      child: KrizotApp(),
    ),
  );
}
