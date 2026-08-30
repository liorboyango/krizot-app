import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../app_config/l10n/gen/app_localizations.dart';
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
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('he'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }

  @override
  void dispose() {
    disposeAllSingletons();
    super.dispose();
  }
}
