import 'user_model.dart';
import 'station_model.dart';

/// Schedule data model matching backend API contract.
class ScheduleModel {
  final String id;
  final String stationId;
  final String? userId;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;
  final UserModel? user;
  final StationModel? station;

  const ScheduleModel({
    required this.id,
    required this.stationId,
    this.userId,
    required this.startTime,
    required this.endTime,
    this.notes,
    this.user,
    this.station,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id']?.toString() ?? '',
      stationId: json['stationId']?.toString() ?? '',
      userId: json['userId']?.toString(),
      startTime: DateTime.parse(json['startTime'].toString()),
      endTime: DateTime.parse(json['endTime'].toString()),
      notes: json['notes']?.toString(),
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      station: json['station'] != null
          ? StationModel.fromJson(json['station'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Whether this shift has an assigned user.
  bool get isAssigned => userId != null && userId!.isNotEmpty;

  /// Shift status: covered, open, or critical.
  String get shiftStatus {
    if (!isAssigned) {
      final now = DateTime.now();
      if (startTime.isBefore(now)) return 'critical';
      return 'open';
    }
    return 'covered';
  }

  /// Formatted shift time range (e.g., 07:00 - 15:00).
  String get shiftTimeRange {
    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${fmt(startTime)} - ${fmt(endTime)}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stationId': stationId,
        if (userId != null) 'userId': userId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        if (notes != null) 'notes': notes,
      };
}

/// Dashboard stats model from /api/schedules/stats.
class DashboardStats {
  final int totalStations;
  final int activeStations;
  final int onDuty;
  final int openShifts;
  final int criticalShifts;
  final String date;
  final List<ScheduleModel> todaySchedules;

  const DashboardStats({
    required this.totalStations,
    required this.activeStations,
    required this.onDuty,
    required this.openShifts,
    required this.criticalShifts,
    required this.date,
    required this.todaySchedules,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final schedulesList = (json['todaySchedules'] as List<dynamic>? ?? [])
        .map((s) => ScheduleModel.fromJson(s as Map<String, dynamic>))
        .toList();
    return DashboardStats(
      totalStations: (json['totalStations'] as num?)?.toInt() ?? 0,
      activeStations: (json['activeStations'] as num?)?.toInt() ?? 0,
      onDuty: (json['onDuty'] as num?)?.toInt() ?? 0,
      openShifts: (json['openShifts'] as num?)?.toInt() ?? 0,
      criticalShifts: (json['criticalShifts'] as num?)?.toInt() ?? 0,
      date: json['date']?.toString() ?? '',
      todaySchedules: schedulesList,
    );
  }

  factory DashboardStats.empty() => const DashboardStats(
        totalStations: 0,
        activeStations: 0,
        onDuty: 0,
        openShifts: 0,
        criticalShifts: 0,
        date: '',
        todaySchedules: [],
      );
}
