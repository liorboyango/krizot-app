/// Krizot App — Entry Point
///
/// Initialises the API client and wraps the app in a [ProviderScope]
/// so all Riverpod providers are available throughout the widget tree.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise the Dio-based API client (sets up interceptors, base URL, etc.)
  ApiClient.instance.init();

  runApp(
    // ProviderScope is required at the root for flutter_riverpod
    const ProviderScope(
      child: KrizotApp(),
    ),
  );
}
