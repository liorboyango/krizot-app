import 'package:cloud_firestore/cloud_firestore.dart';

/// How an uncertified trainee is trained toward a certification.
enum TrainingType {
  /// A staffed drill — the target certification defines how many holders of
  /// which certifications must run it (Certification.simulationStaff).
  simulation,

  /// The trainee shadows exactly one certified spectator.
  spectation,

  /// One-on-one instruction by one certified tutor.
  tutoring;

  static TrainingType fromString(String? value) =>
      TrainingType.values.firstWhere(
        (type) => type.name == value,
        orElse: () => TrainingType.tutoring,
      );

  /// Session types where a single certified trainer is required.
  bool get isOneOnOne => this != TrainingType.simulation;
}

/// A scheduled training block: one or more certified trainers bringing an
/// uncertified [traineeId] toward [certificationId]. Rendered on the
/// scheduler grid alongside station shifts; its [priority] defaults to the
/// certification's level (higher level = higher priority) but is editable.
class TrainingSession {
  final String id;
  final String certificationId;
  final TrainingType type;

  /// Null = open slot, waiting for a trainee.
  final String? traineeId;
  final List<String> trainerIds;
  final DateTime start;
  final DateTime end;

  /// 'YYYY-MM-DD' of [start] — enables cheap day-grid queries.
  final String dayKey;
  final int priority;
  final String? notes;
  final String? createdBy;
  final String? lastModifiedBy;
  final DateTime? lastModifiedAt;

  const TrainingSession({
    required this.id,
    required this.certificationId,
    required this.type,
    this.traineeId,
    this.trainerIds = const [],
    required this.start,
    required this.end,
    required this.dayKey,
    this.priority = 0,
    this.notes,
    this.createdBy,
    this.lastModifiedBy,
    this.lastModifiedAt,
  });

  Duration get duration => end.difference(start);

  bool overlaps(DateTime otherStart, DateTime otherEnd) =>
      start.isBefore(otherEnd) && otherStart.isBefore(end);

  bool involves(String userId) =>
      traineeId == userId || trainerIds.contains(userId);

  factory TrainingSession.fromMap(String id, Map<String, dynamic> map) =>
      TrainingSession(
        id: id,
        certificationId: map['certificationId'] as String? ?? '',
        type: TrainingType.fromString(map['type'] as String?),
        traineeId: map['traineeId'] as String?,
        trainerIds: List<String>.from(map['trainerIds'] as List? ?? const []),
        start: (map['start'] as Timestamp).toDate(),
        end: (map['end'] as Timestamp).toDate(),
        dayKey: map['dayKey'] as String? ?? '',
        priority: (map['priority'] as num?)?.toInt() ?? 0,
        notes: map['notes'] as String?,
        createdBy: map['createdBy'] as String?,
        lastModifiedBy: map['lastModifiedBy'] as String?,
        lastModifiedAt: (map['lastModifiedAt'] as Timestamp?)?.toDate(),
      );

  factory TrainingSession.fromDoc(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      TrainingSession.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'certificationId': certificationId,
        'type': type.name,
        'traineeId': traineeId,
        'trainerIds': trainerIds,
        'start': Timestamp.fromDate(start),
        'end': Timestamp.fromDate(end),
        'dayKey': dayKey,
        'priority': priority,
        if (notes != null) 'notes': notes,
        if (createdBy != null) 'createdBy': createdBy,
        if (lastModifiedBy != null) 'lastModifiedBy': lastModifiedBy,
        if (lastModifiedAt != null)
          'lastModifiedAt': Timestamp.fromDate(lastModifiedAt!),
      };
}
