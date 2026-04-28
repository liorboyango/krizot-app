/// Schedule model representing a shift assignment.
///
/// Maps to the backend Schedule schema:
/// { id, stationId, userId, startTime, endTime, notes, station, user }
library;

import 'user.dart';
import 'station.dart';

/// Immutable data class for a Krizot schedule entry.
class Schedule {
  const Schedule({
    required this.id,
    required this.stationId,
    required this.startTime,
    required this.endTime,
    this.userId,
    this.notes,
    this.station,
    this.user,
  });

  final String id;
  final String stationId;
  final String? userId;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;

  /// Nested station object (populated in some responses).
  final Station? station;

  /// Nested user object (populated in some responses).
  final User? user;

  /// Whether this shift has an assigned user.
  bool get isAssigned => userId != null && userId!.isNotEmpty;

  /// Shift duration in hours.
  double get durationHours =>
      endTime.difference(startTime).inMinutes / 60.0;

  /// Construct from a JSON map returned by the API.
  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      stationId: (json['stationId'] as String?) ??
          (json['station'] != null
              ? (json['station'] as Map<String, dynamic>)['id'] as String
              : ''),
      userId: json['userId'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      notes: json['notes'] as String?,
      station: json['station'] != null
          ? Station.fromJson(json['station'] as Map<String, dynamic>)
          : null,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Serialise to a JSON map for API create requests.
  Map<String, dynamic> toJson() => {
        'stationId': stationId,
        if (userId != null) 'userId': userId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        if (notes != null) 'notes': notes,
      };

  /// Create a copy with optional field overrides.
  Schedule copyWith({
    String? id,
    String? stationId,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    Station? station,
    User? user,
  }) {
    return Schedule(
      id: id ?? this.id,
      stationId: stationId ?? this.stationId,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      station: station ?? this.station,
      user: user ?? this.user,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Schedule &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Schedule(id: $id, stationId: $stationId, userId: $userId, '
      'startTime: $startTime, endTime: $endTime)';
}

/// Stats returned by GET /api/schedules/stats.
class ScheduleStats {
  const ScheduleStats({
    required this.totalStations,
    required this.onDuty,
    required this.openShifts,
    required this.criticalShifts,
    this.activeStations,
    this.date,
    this.todaySchedules,
  });

  final int totalStations;
  final int onDuty;
  final int openShifts;
  final int criticalShifts;
  final int? activeStations;
  final String? date;
  final List<Schedule>? todaySchedules;

  factory ScheduleStats.fromJson(Map<String, dynamic> json) {
    final List<Schedule>? todaySchedules =
        json['todaySchedules'] != null
            ? (json['todaySchedules'] as List<dynamic>)
                .map((e) => Schedule.fromJson(e as Map<String, dynamic>))
                .toList()
            : null;

    return ScheduleStats(
      totalStations: (json['totalStations'] as num?)?.toInt() ?? 0,
      onDuty: (json['onDuty'] as num?)?.toInt() ??
          (json['onDutyNow'] as num?)?.toInt() ??
          0,
      openShifts: (json['openShifts'] as num?)?.toInt() ??
          (json['openShiftsToday'] as num?)?.toInt() ??
          0,
      criticalShifts: (json['criticalShifts'] as num?)?.toInt() ?? 0,
      activeStations: (json['activeStations'] as num?)?.toInt(),
      date: json['date'] as String?,
      todaySchedules: todaySchedules,
    );
  }

  @override
  String toString() =>
      'ScheduleStats(totalStations: $totalStations, onDuty: $onDuty, '
      'openShifts: $openShifts, criticalShifts: $criticalShifts)';
}

/// A single day entry in the weekly grid.
class WeekDay {
  const WeekDay({
    required this.date,
    required this.dayName,
    this.index,
  });

  final String date;
  final String dayName;
  final int? index;

  factory WeekDay.fromJson(Map<String, dynamic> json) {
    return WeekDay(
      date: json['date'] as String,
      dayName: json['dayName'] as String,
      index: json['index'] as int?,
    );
  }
}

/// A station row in the weekly schedule grid.
class WeeklyGridRow {
  const WeeklyGridRow({
    required this.station,
    required this.days,
  });

  final Station station;

  /// Map of day index (0-6) → list of schedules for that day.
  final Map<int, List<Schedule>> days;

  factory WeeklyGridRow.fromJson(Map<String, dynamic> json) {
    final stationJson = json['station'] as Map<String, dynamic>;
    final daysJson = json['days'];

    final Map<int, List<Schedule>> days = {};

    List<Schedule> parseScheduleList(dynamic value) {
      if (value == null) return const [];
      return (value as List<dynamic>)
          .map((e) => Schedule.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (daysJson is Map<String, dynamic>) {
      daysJson.forEach((key, value) {
        final index = int.tryParse(key) ?? 0;
        days[index] = parseScheduleList(value);
      });
    } else if (daysJson is List<dynamic>) {
      for (var i = 0; i < daysJson.length; i++) {
        final entry = daysJson[i];
        if (entry is Map<String, dynamic> && entry.containsKey('schedules')) {
          final index = (entry['index'] as num?)?.toInt() ?? i;
          days[index] = parseScheduleList(entry['schedules']);
        } else {
          days[i] = parseScheduleList(entry);
        }
      }
    }

    return WeeklyGridRow(
      station: Station.fromJson(stationJson),
      days: days,
    );
  }
}

/// Full weekly schedule grid response.
class WeeklySchedule {
  const WeeklySchedule({
    required this.weekStart,
    required this.weekEnd,
    required this.days,
    required this.grid,
  });

  final String weekStart;
  final String weekEnd;
  final List<WeekDay> days;
  final List<WeeklyGridRow> grid;

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    final daysList = (json['days'] as List<dynamic>)
        .map((e) => WeekDay.fromJson(e as Map<String, dynamic>))
        .toList();

    final gridList = (json['grid'] as List<dynamic>)
        .map((e) => WeeklyGridRow.fromJson(e as Map<String, dynamic>))
        .toList();

    return WeeklySchedule(
      weekStart: json['weekStart'] as String,
      weekEnd: json['weekEnd'] as String,
      days: daysList,
      grid: gridList,
    );
  }
}

/// A single assignment request for bulk assign.
class AssignmentRequest {
  const AssignmentRequest({
    this.scheduleId,
    this.stationId,
    required this.userId,
    this.startTime,
    this.endTime,
  });

  final String? scheduleId;
  final String? stationId;
  final String userId;
  final DateTime? startTime;
  final DateTime? endTime;

  Map<String, dynamic> toJson() => {
        if (scheduleId != null) 'scheduleId': scheduleId,
        if (stationId != null) 'stationId': stationId,
        'userId': userId,
        if (startTime != null) 'startTime': startTime!.toIso8601String(),
        if (endTime != null) 'endTime': endTime!.toIso8601String(),
      };
}
