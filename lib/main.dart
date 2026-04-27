import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

/// Krizot application entry point.
///
/// Wraps the app in a [ProviderScope] for Riverpod state management.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: KrizotApp(),
    ),
  );
}
