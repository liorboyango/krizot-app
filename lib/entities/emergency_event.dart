import 'package:cloud_firestore/cloud_firestore.dart';

import 'org_scope.dart';

enum EmergencyStatus {
  active,
  resolved;

  static EmergencyStatus fromString(String? value) =>
      EmergencyStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => EmergencyStatus.active,
      );
}

/// A responder reference denormalized onto the event so the dispatch UI never
/// needs read access to /users.
class AlertedUser {
  final String uid;
  final String displayName;

  const AlertedUser({required this.uid, required this.displayName});

  factory AlertedUser.fromMap(Map<String, dynamic> map) => AlertedUser(
    uid: map['uid'] as String? ?? '',
    displayName: map['displayName'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {'uid': uid, 'displayName': displayName};
}

/// A triggered emergency call-out. Created only by the `triggerEmergency`
/// callable; per-responder acks live in the `acks/{uid}` subcollection.
class EmergencyEvent {
  final String id;
  final String eventTypeId;
  final String eventTypeName;
  final String triggeredBy;
  final DateTime? triggeredAt;
  final EmergencyStatus status;
  final List<String> alertedUserIds;
  final List<AlertedUser> alertedUsers;
  final List<String> stationIds;

  /// Unit copied from the event type at trigger time so the active-events
  /// board can filter per unit. Null = organization-wide.
  final Site? site;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  const EmergencyEvent({
    required this.id,
    required this.eventTypeId,
    required this.eventTypeName,
    required this.triggeredBy,
    this.triggeredAt,
    this.status = EmergencyStatus.active,
    this.alertedUserIds = const [],
    this.alertedUsers = const [],
    this.stationIds = const [],
    this.site,
    this.resolvedBy,
    this.resolvedAt,
  });

  factory EmergencyEvent.fromMap(String id, Map<String, dynamic> map) =>
      EmergencyEvent(
        id: id,
        eventTypeId: map['eventTypeId'] as String? ?? '',
        eventTypeName: map['eventTypeName'] as String? ?? '',
        triggeredBy: map['triggeredBy'] as String? ?? '',
        triggeredAt: (map['triggeredAt'] as Timestamp?)?.toDate(),
        status: EmergencyStatus.fromString(map['status'] as String?),
        alertedUserIds: List<String>.from(
          map['alertedUserIds'] as List? ?? const [],
        ),
        alertedUsers: (map['alertedUsers'] as List? ?? const [])
            .map(
              (u) => AlertedUser.fromMap(Map<String, dynamic>.from(u as Map)),
            )
            .toList(),
        stationIds: List<String>.from(map['stationIds'] as List? ?? const []),
        site: Site.fromString(map['site'] as String?),
        resolvedBy: map['resolvedBy'] as String?,
        resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      );

  factory EmergencyEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      EmergencyEvent.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
    'eventTypeId': eventTypeId,
    'eventTypeName': eventTypeName,
    'triggeredBy': triggeredBy,
    if (triggeredAt != null) 'triggeredAt': Timestamp.fromDate(triggeredAt!),
    'status': status.name,
    'alertedUserIds': alertedUserIds,
    'alertedUsers': alertedUsers.map((u) => u.toMap()).toList(),
    'stationIds': stationIds,
    if (site != null) 'site': site!.wireName,
    if (resolvedBy != null) 'resolvedBy': resolvedBy,
    if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
  };
}

/// One responder's acknowledgement of an emergency event.
class EmergencyAck {
  final String uid;
  final DateTime? ackAt;

  const EmergencyAck({required this.uid, this.ackAt});

  factory EmergencyAck.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      EmergencyAck(
        uid: doc.id,
        ackAt: ((doc.data() ?? {})['ackAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
    'ackAt': ackAt != null ? Timestamp.fromDate(ackAt!) : null,
  };
}
