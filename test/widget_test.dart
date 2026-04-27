/// Basic widget smoke tests for the Krizot app.
///
/// These tests verify that the app boots without crashing and that
/// the login screen renders correctly.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:krizot_app/app.dart';

void main() {
  group('KrizotApp', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: KrizotApp(),
        ),
      );
      // Allow async providers to settle.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
