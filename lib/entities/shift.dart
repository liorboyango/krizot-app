import 'package:cloud_firestore/cloud_firestore.dart';

enum ShiftStatus {
  open,
  assigned;

  static ShiftStatus fromString(String? value) => ShiftStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => ShiftStatus.open,
      );
}

enum ShiftSource {
  manual,
  autoFill,
  healing;

  static ShiftSource fromString(String? value) => ShiftSource.values.firstWhere(
        (source) => source.name == value,
        orElse: () => ShiftSource.manual,
      );
}

class Shift {
  final String id;
  final String stationId;

  /// Null = open shift.
  final String? userId;
  final DateTime start;
  final DateTime end;

  /// 'YYYY-MM-DD' of [start] — enables cheap day-grid queries.
  final String dayKey;
  final ShiftStatus status;

  /// Reset to false by the backend whenever a manager-side change touches
  /// the assignee; set to true by the assignee's Acknowledge action.
  final bool acknowledged;
  final DateTime? ackAt;
  final String? lastModifiedBy;
  final DateTime? lastModifiedAt;
  final String? createdBy;
  final ShiftSource source;
  final String? notes;

  const Shift({
    required this.id,
    required this.stationId,
    this.userId,
    required this.start,
    required this.end,
    required this.dayKey,
    this.status = ShiftStatus.open,
    this.acknowledged = false,
    this.ackAt,
    this.lastModifiedBy,
    this.lastModifiedAt,
    this.createdBy,
    this.source = ShiftSource.manual,
    this.notes,
  });

  bool get isAssigned => userId != null;
  Duration get duration => end.difference(start);

  bool overlaps(DateTime otherStart, DateTime otherEnd) =>
      start.isBefore(otherEnd) && otherStart.isBefore(end);

  factory Shift.fromMap(String id, Map<String, dynamic> map) => Shift(
        id: id,
        stationId: map['stationId'] as String? ?? '',
        userId: map['userId'] as String?,
        start: (map['start'] as Timestamp).toDate(),
        end: (map['end'] as Timestamp).toDate(),
        dayKey: map['dayKey'] as String? ?? '',
        status: ShiftStatus.fromString(map['status'] as String?),
        acknowledged: map['acknowledged'] as bool? ?? false,
        ackAt: (map['ackAt'] as Timestamp?)?.toDate(),
        lastModifiedBy: map['lastModifiedBy'] as String?,
        lastModifiedAt: (map['lastModifiedAt'] as Timestamp?)?.toDate(),
        createdBy: map['createdBy'] as String?,
        source: ShiftSource.fromString(map['source'] as String?),
        notes: map['notes'] as String?,
      );

  factory Shift.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Shift.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'stationId': stationId,
        'userId': userId,
        'start': Timestamp.fromDate(start),
        'end': Timestamp.fromDate(end),
        'dayKey': dayKey,
        'status': status.name,
        'acknowledged': acknowledged,
        'ackAt': ackAt != null ? Timestamp.fromDate(ackAt!) : null,
        if (lastModifiedBy != null) 'lastModifiedBy': lastModifiedBy,
        if (lastModifiedAt != null)
          'lastModifiedAt': Timestamp.fromDate(lastModifiedAt!),
        if (createdBy != null) 'createdBy': createdBy,
        'source': source.name,
        if (notes != null) 'notes': notes,
      };
}
