import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krizot_app/providers/schedule_provider.dart';

void main() {
  group('ScheduleViewMode', () {
    test('default view mode is week', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(scheduleViewModeProvider),
        ScheduleViewMode.week,
      );
    });

    test('can change view mode to day', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(scheduleViewModeProvider.notifier).state =
          ScheduleViewMode.day;
      expect(
        container.read(scheduleViewModeProvider),
        ScheduleViewMode.day,
      );
    });

    test('can change view mode to list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(scheduleViewModeProvider.notifier).state =
          ScheduleViewMode.list;
      expect(
        container.read(scheduleViewModeProvider),
        ScheduleViewMode.list,
      );
    });
  });

  group('selectedWeekProvider', () {
    test('default week starts on Monday', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final week = container.read(selectedWeekProvider);
      // Monday = weekday 1
      expect(week.weekday, 1);
    });

    test('can navigate to next week', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final initial = container.read(selectedWeekProvider);
      container.read(selectedWeekProvider.notifier).state =
          initial.add(const Duration(days: 7));
      final next = container.read(selectedWeekProvider);
      expect(next.difference(initial).inDays, 7);
    });

    test('can navigate to previous week', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final initial = container.read(selectedWeekProvider);
      container.read(selectedWeekProvider.notifier).state =
          initial.subtract(const Duration(days: 7));
      final prev = container.read(selectedWeekProvider);
      expect(initial.difference(prev).inDays, 7);
    });
  });

  group('AssignmentPanelNotifier', () {
    test('initial state is closed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(assignmentPanelProvider);
      expect(state.isOpen, isFalse);
      expect(state.selectedSchedule, isNull);
    });

    test('close resets state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(assignmentPanelProvider.notifier).close();
      final state = container.read(assignmentPanelProvider);
      expect(state.isOpen, isFalse);
      expect(state.selectedSchedule, isNull);
    });
  });

  group('SchedulesListState', () {
    test('copyWith preserves unchanged fields', () {
      const state = SchedulesListState(
        schedules: [],
        isLoading: false,
        page: 1,
        totalPages: 5,
      );
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
      expect(updated.page, 1);
      expect(updated.totalPages, 5);
    });

    test('copyWith clears error when not provided', () {
      const state = SchedulesListState(
        schedules: [],
        error: 'some error',
      );
      final updated = state.copyWith(isLoading: true);
      // error is not passed, so it should be null (cleared)
      expect(updated.error, isNull);
    });
  });
}
