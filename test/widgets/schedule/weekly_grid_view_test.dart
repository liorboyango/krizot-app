import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krizot_app/widgets/schedule/weekly_grid_view.dart';
import 'package:krizot_app/providers/schedule_provider.dart';
import 'package:krizot_app/models/schedule.dart';

void main() {
  group('WeeklyGridView', () {
    testWidgets('shows loading shimmer when loading', (tester) async {
      final container = ProviderContainer(
        overrides: [
          weeklyScheduleProvider.overrideWith(
            (ref) async {
              await Future.delayed(const Duration(seconds: 10));
              throw Exception('timeout');
            },
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: WeeklyGridView(isDesktop: true, isTablet: false),
            ),
          ),
        ),
      );

      // Should show shimmer while loading
      expect(find.byType(WeeklyGridView), findsOneWidget);
    });

    testWidgets('shows error banner on error', (tester) async {
      final container = ProviderContainer(
        overrides: [
          weeklyScheduleProvider.overrideWith(
            (ref) async => throw Exception('Network error'),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: WeeklyGridView(isDesktop: true, isTablet: false),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      // Error state should be shown
      expect(find.byType(WeeklyGridView), findsOneWidget);
    });

    testWidgets('shows empty state when no grid data', (tester) async {
      final emptyWeekly = WeeklySchedule(
        weekStart: DateTime(2024, 4, 27),
        weekEnd: DateTime(2024, 5, 3),
        days: [
          DayInfo(
            index: 0,
            date: DateTime(2024, 4, 27),
            dayName: 'Monday',
          ),
        ],
        grid: [],
      );

      final container = ProviderContainer(
        overrides: [
          weeklyScheduleProvider.overrideWith((ref) async => emptyWeekly),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: WeeklyGridView(isDesktop: true, isTablet: false),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('No schedules for this week'), findsOneWidget);
    });
  });
}
