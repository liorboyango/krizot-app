import 'package:flutter/material.dart';

/// A daily activity window ('HH:mm'–'HH:mm') for on-demand stations.
class TimeWindow {
  /// 'HH:mm', 24h.
  final String start;
  final String end;

  const TimeWindow({required this.start, required this.end});

  factory TimeWindow.fromMap(Map<String, dynamic> map) => TimeWindow(
        start: map['start'] as String? ?? '00:00',
        end: map['end'] as String? ?? '00:00',
      );

  Map<String, dynamic> toMap() => {'start': start, 'end': end};

  TimeOfDay get startTime => _parse(start);
  TimeOfDay get endTime => _parse(end);

  static TimeOfDay _parse(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  int get startMinutes => startTime.hour * 60 + startTime.minute;
  int get endMinutes => endTime.hour * 60 + endTime.minute;

  /// Whether [time] falls inside this window (start inclusive, end exclusive).
  bool contains(TimeOfDay time) {
    final minutes = time.hour * 60 + time.minute;
    return minutes >= startMinutes && minutes < endMinutes;
  }

  @override
  String toString() => '$start–$end';
}
