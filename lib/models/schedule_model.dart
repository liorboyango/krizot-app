/// Data model for a Krizot schedule entry (shift assignment).
library;

/// Represents a single shift assignment linking a station, a user, and a time window.
class ScheduleModel {
  const ScheduleModel({
    required this.id,
    required this.stationId,
    required this.startTime,
    required this.endTime,
    this.userId,
    this.stationName,
    this.userName,
  });

  /// Unique schedule identifier.
  final String id;

  /// ID of the assigned station.
  final String stationId;

  /// Shift start time (UTC).
  final DateTime startTime;

  /// Shift end time (UTC).
  final DateTime endTime;

  /// ID of the assigned user (null = open shift).
  final String? userId;

  // Denormalised display fields (populated by API joins).

  /// Station display name.
  final String? stationName;

  /// Assigned user display name.
  final String? userName;

  /// Whether this shift has an assigned user.
  bool get isAssigned => userId != null && userId!.isNotEmpty;

  /// Duration of the shift.
  Duration get duration => endTime.difference(startTime);

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id']?.toString() ?? '',
      stationId: json['stationId']?.toString() ?? '',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      userId: json['userId']?.toString(),
      stationName: json['station']?['name'] as String? ??
          json['stationName'] as String?,
      userName: json['user']?['name'] as String? ??
          json['userName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stationId': stationId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        if (userId != null) 'userId': userId,
      };

  ScheduleModel copyWith({
    String? id,
    String? stationId,
    DateTime? startTime,
    DateTime? endTime,
    String? userId,
    String? stationName,
    String? userName,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      stationId: stationId ?? this.stationId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      userId: userId ?? this.userId,
      stationName: stationName ?? this.stationName,
      userName: userName ?? this.userName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ScheduleModel(id: $id, stationId: $stationId, startTime: $startTime, endTime: $endTime, userId: $userId)';
}
