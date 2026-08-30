import 'package:cloud_firestore/cloud_firestore.dart';

/// One presence window on a user's availability calendar: arriving at
/// [start], leaving at [end] — may span several days (e.g. arriving
/// 13.9 12:00, leaving 15.9 15:00). A user with no window covering a time
/// is not schedulable at that time.
class AvailabilityWindow {
  final String id;
  final String userId;
  final DateTime start;
  final DateTime end;
  final String? notes;
  final DateTime? createdAt;

  const AvailabilityWindow({
    required this.id,
    required this.userId,
    required this.start,
    required this.end,
    this.notes,
    this.createdAt,
  });

  bool overlaps(DateTime otherStart, DateTime otherEnd) =>
      start.isBefore(otherEnd) && otherStart.isBefore(end);

  /// Whether the window fully contains [rangeStart, rangeEnd].
  bool covers(DateTime rangeStart, DateTime rangeEnd) =>
      !start.isAfter(rangeStart) && !end.isBefore(rangeEnd);

  factory AvailabilityWindow.fromMap(String id, Map<String, dynamic> map) =>
      AvailabilityWindow(
        id: id,
        userId: map['userId'] as String? ?? '',
        start: (map['start'] as Timestamp).toDate(),
        end: (map['end'] as Timestamp).toDate(),
        notes: map['notes'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  factory AvailabilityWindow.fromDoc(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      AvailabilityWindow.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'start': Timestamp.fromDate(start),
        'end': Timestamp.fromDate(end),
        if (notes != null) 'notes': notes,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      };
}
