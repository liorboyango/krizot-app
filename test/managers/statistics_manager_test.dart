import 'package:flutter_test/flutter_test.dart';
import 'package:krizot_app/entities/availability_window.dart';
import 'package:krizot_app/entities/shift.dart';
import 'package:krizot_app/entities/training_session.dart';
import 'package:krizot_app/managers/statistics_manager.dart';

/// Pure aggregation helpers behind the Statistics screen.
void main() {
  final monday = DateTime(2026, 8, 24); // a Monday
  DateTime at(int day, int hour) =>
      DateTime(2026, 8, 24 + day).add(Duration(hours: hour));

  Shift shift(String id, String? userId, int day, int startHour, int endHour) =>
      Shift(
        id: id,
        stationId: 'gate',
        userId: userId,
        start: at(day, startHour),
        end: at(day, endHour),
        dayKey: '2026-08-${24 + day}',
      );

  TrainingSession session(
    String id, {
    String? traineeId,
    List<String> trainerIds = const [],
    int hours = 2,
  }) =>
      TrainingSession(
        id: id,
        certificationId: 'certMedic',
        type: TrainingType.tutoring,
        traineeId: traineeId,
        trainerIds: trainerIds,
        start: at(0, 8),
        end: at(0, 8 + hours),
        dayKey: '2026-08-24',
      );

  AvailabilityWindow window(
          String id, String userId, DateTime start, DateTime end) =>
      AvailabilityWindow(id: id, userId: userId, start: start, end: end);

  test('stationTimeByUser sums assigned durations and skips open shifts', () {
    final time = StatisticsManager.stationTimeByUser([
      shift('s1', 'alice', 0, 8, 10),
      shift('s2', 'alice', 1, 8, 11),
      shift('s3', 'bob', 0, 10, 12),
      shift('s4', null, 0, 12, 14),
    ]);
    expect(time, hasLength(2));
    expect(time['alice'], const Duration(hours: 5));
    expect(time['bob'], const Duration(hours: 2));
    expect(
      StatisticsManager.shiftCountByUser([
        shift('s1', 'alice', 0, 8, 10),
        shift('s2', 'alice', 1, 8, 11),
        shift('s4', null, 0, 12, 14),
      ]),
      {'alice': 2},
    );
  });

  test('trainingTimeByUser credits trainee and trainers once each', () {
    final time = StatisticsManager.trainingTimeByUser([
      session('t1', traineeId: 'rookie', trainerIds: ['medic'], hours: 2),
      session('t2', trainerIds: ['medic', 'rookie'], hours: 3),
    ]);
    expect(time['rookie'], const Duration(hours: 5));
    expect(time['medic'], const Duration(hours: 5));
    expect(
      StatisticsManager.sessionCountByUser([
        session('t1', traineeId: 'rookie', trainerIds: ['medic']),
        session('t2', trainerIds: ['medic']),
      ]),
      {'rookie': 1, 'medic': 2},
    );
  });

  test('presenceByUser clips windows to the range and merges overlaps', () {
    final weekEnd = monday.add(const Duration(days: 7));
    final presence = StatisticsManager.presenceByUser([
      // Starts before the week — only the in-range 8h counts.
      window('w1', 'alice', monday.subtract(const Duration(hours: 4)),
          monday.add(const Duration(hours: 8))),
      // Overlaps w1 by 2h — the overlap must not double-count.
      window('w2', 'alice', monday.add(const Duration(hours: 6)),
          monday.add(const Duration(hours: 12))),
      // Fully outside the week.
      window('w3', 'bob', weekEnd, weekEnd.add(const Duration(hours: 5))),
    ], monday, weekEnd);
    expect(presence['alice'], const Duration(hours: 12));
    expect(presence['bob'], Duration.zero);
    // No windows at all → absent from the map (UI shows always-present).
    expect(presence.containsKey('carol'), isFalse);
  });

  test('presenceByUser ignores a window contained in an earlier one', () {
    final weekEnd = monday.add(const Duration(days: 7));
    final presence = StatisticsManager.presenceByUser([
      window('w1', 'alice', monday, monday.add(const Duration(hours: 10))),
      window('w2', 'alice', monday.add(const Duration(hours: 2)),
          monday.add(const Duration(hours: 5))),
      window('w3', 'alice', monday.add(const Duration(hours: 8)),
          monday.add(const Duration(hours: 14))),
    ], monday, weekEnd);
    expect(presence['alice'], const Duration(hours: 14));
  });
}
