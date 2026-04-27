/// Root application widget for Krizot.
///
/// Configures:
/// - Material 3 theme with custom [AppTheme]
/// - [GoRouter]-based navigation
/// - Global error / loading overlays
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'utils/app_theme.dart';
import 'router/app_router.dart';

/// The root widget of the Krizot application.
///
/// Consumes [appRouterProvider] so that navigation reacts to auth state
/// changes (e.g., redirect to login when JWT expires).
class KrizotApp extends ConsumerWidget {
  const KrizotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Krizot',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // Router
      routerConfig: router,

      // Localisation
      locale: const Locale('en'),
    );
  }
}
