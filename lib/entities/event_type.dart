import 'package:cloud_firestore/cloud_firestore.dart';

enum EventPriority {
  high,
  critical;

  static EventPriority fromString(String? value) =>
      EventPriority.values.firstWhere(
        (priority) => priority.name == value,
        orElse: () => EventPriority.high,
      );
}

/// A pre-defined emergency scenario: which certifications mark a responder
/// (holder of ANY listed certification) and which stations are involved.
class EventType {
  final String id;
  final String name;
  final String? description;
  final List<String> responderCertifications;
  final List<String> stationIds;
  final EventPriority priority;
  final bool active;
  final DateTime? createdAt;

  const EventType({
    required this.id,
    required this.name,
    this.description,
    this.responderCertifications = const [],
    this.stationIds = const [],
    this.priority = EventPriority.high,
    this.active = true,
    this.createdAt,
  });

  factory EventType.fromMap(String id, Map<String, dynamic> map) => EventType(
        id: id,
        name: map['name'] as String? ?? '',
        description: map['description'] as String?,
        responderCertifications: List<String>.from(
            map['responderCertifications'] as List? ?? const []),
        stationIds: List<String>.from(map['stationIds'] as List? ?? const []),
        priority: EventPriority.fromString(map['priority'] as String?),
        active: map['active'] as bool? ?? true,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  factory EventType.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      EventType.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'name': name,
        if (description != null) 'description': description,
        'responderCertifications': responderCertifications,
        'stationIds': stationIds,
        'priority': priority.name,
        'active': active,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      };
}
