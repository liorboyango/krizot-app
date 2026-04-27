/// Schedule model representing a shift assignment
class Schedule {
  final String id;
  final String stationId;
  final String? userId;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;
  final ScheduleStatus status;
  final StationInfo? station;
  final UserInfo? user;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Schedule({
    required this.id,
    required this.stationId,
    this.userId,
    required this.startTime,
    required this.endTime,
    this.notes,
    this.status = ScheduleStatus.open,
    this.station,
    this.user,
    this.createdAt,
    this.updatedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      stationId: json['stationId'] as String,
      userId: json['userId'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      notes: json['notes'] as String?,
      status: _parseStatus(json),
      station: json['station'] != null
          ? StationInfo.fromJson(json['station'] as Map<String, dynamic>)
          : null,
      user: json['user'] != null
          ? UserInfo.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  static ScheduleStatus _parseStatus(Map<String, dynamic> json) {
    // Derive status from userId presence or explicit status field
    if (json['status'] != null) {
      switch (json['status'] as String) {
        case 'CRITICAL':
          return ScheduleStatus.critical;
        case 'COVERED':
          return ScheduleStatus.covered;
        case 'OPEN':
        default:
          return ScheduleStatus.open;
      }
    }
    return json['userId'] != null ? ScheduleStatus.covered : ScheduleStatus.open;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stationId': stationId,
      if (userId != null) 'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }

  Schedule copyWith({
    String? id,
    String? stationId,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    ScheduleStatus? status,
    StationInfo? station,
    UserInfo? user,
  }) {
    return Schedule(
      id: id ?? this.id,
      stationId: stationId ?? this.stationId,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      station: station ?? this.station,
      user: user ?? this.user,
    );
  }

  String get shiftTimeLabel {
    final start = _formatTime(startTime);
    final end = _formatTime(endTime);
    return '$start-$end';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get isCovered => userId != null;
  bool get isOpen => userId == null && status != ScheduleStatus.critical;
  bool get isCritical => status == ScheduleStatus.critical;
}

enum ScheduleStatus { covered, open, critical }

/// Lightweight station info embedded in schedule responses
class StationInfo {
  final String id;
  final String name;
  final String location;

  const StationInfo({
    required this.id,
    required this.name,
    required this.location,
  });

  factory StationInfo.fromJson(Map<String, dynamic> json) {
    return StationInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String? ?? '',
    );
  }
}

/// Lightweight user info embedded in schedule responses
class UserInfo {
  final String id;
  final String name;
  final String email;
  final String? role;

  const UserInfo({
    required this.id,
    required this.name,
    required this.email,
    this.role,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['email'] as String,
      email: json['email'] as String,
      role: json['role'] as String?,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

/// Weekly grid data returned by GET /api/schedules/week
class WeeklySchedule {
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<DayInfo> days;
  final List<StationWeekRow> grid;

  const WeeklySchedule({
    required this.weekStart,
    required this.weekEnd,
    required this.days,
    required this.grid,
  });

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    final daysJson = json['days'] as List<dynamic>? ?? [];
    final gridJson = json['grid'] as List<dynamic>? ?? [];
    return WeeklySchedule(
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
      days: daysJson
          .map((d) => DayInfo.fromJson(d as Map<String, dynamic>))
          .toList(),
      grid: gridJson
          .map((g) => StationWeekRow.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DayInfo {
  final int index;
  final DateTime date;
  final String dayName;

  const DayInfo({
    required this.index,
    required this.date,
    required this.dayName,
  });

  factory DayInfo.fromJson(Map<String, dynamic> json) {
    return DayInfo(
      index: json['index'] as int? ?? 0,
      date: DateTime.parse(json['date'] as String),
      dayName: json['dayName'] as String? ?? '',
    );
  }
}

class StationWeekRow {
  final StationInfo station;
  /// Map from day index (0-6) to list of schedules
  final Map<int, List<Schedule>> days;

  const StationWeekRow({
    required this.station,
    required this.days,
  });

  factory StationWeekRow.fromJson(Map<String, dynamic> json) {
    final stationJson = json['station'] as Map<String, dynamic>;
    final daysJson = json['days'] as Map<String, dynamic>? ?? {};
    final daysMap = <int, List<Schedule>>{};
    daysJson.forEach((key, value) {
      final dayIndex = int.tryParse(key) ?? 0;
      final schedulesList = (value as List<dynamic>)
          .map((s) => Schedule.fromJson(s as Map<String, dynamic>))
          .toList();
      daysMap[dayIndex] = schedulesList;
    });
    return StationWeekRow(
      station: StationInfo.fromJson(stationJson),
      days: daysMap,
    );
  }
}

/// Schedule stats returned by GET /api/schedules/stats
class ScheduleStats {
  final int totalStations;
  final int activeStations;
  final int onDuty;
  final int openShifts;
  final int criticalShifts;

  const ScheduleStats({
    required this.totalStations,
    required this.activeStations,
    required this.onDuty,
    required this.openShifts,
    required this.criticalShifts,
  });

  factory ScheduleStats.fromJson(Map<String, dynamic> json) {
    return ScheduleStats(
      totalStations: json['totalStations'] as int? ?? 0,
      activeStations: json['activeStations'] as int? ?? 0,
      onDuty: (json['onDuty'] ?? json['onDutyNow']) as int? ?? 0,
      openShifts: (json['openShifts'] ?? json['openShiftsToday']) as int? ?? 0,
      criticalShifts: json['criticalShifts'] as int? ?? 0,
    );
  }
}
