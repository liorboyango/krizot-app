import 'package:flutter/material.dart';

import '../app_config/route_generator.dart';
import '../app_config/service_locator.dart';
import '../utils/app_theme.dart';

class KrizotApp extends StatefulWidget {
  const KrizotApp({super.key});

  @override
  State<KrizotApp> createState() => _KrizotAppState();
}

class _KrizotAppState extends State<KrizotApp> {
  final router = RouteGenerator.router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Krizot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }

  @override
  void dispose() {
    disposeAllSingletons();
    super.dispose();
  }
}
