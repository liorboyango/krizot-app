import 'package:cloud_firestore/cloud_firestore.dart';

import 'org_scope.dart';
import 'time_window.dart';

enum StationStatus {
  active,
  closed;

  static StationStatus fromString(String? value) =>
      StationStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => StationStatus.active,
      );
}

enum ManningType {
  /// Must be manned around the clock. Wire value: '24x7'.
  aroundTheClock,

  /// Only active during [Station.activeWindows] on days it's needed.
  onDemand;

  static const _aroundTheClockWire = '24x7';

  static ManningType fromString(String? value) => value == _aroundTheClockWire
      ? ManningType.aroundTheClock
      : ManningType.onDemand;

  String get wireName =>
      this == ManningType.aroundTheClock ? _aroundTheClockWire : name;
}

class Station {
  final String id;
  final String name;
  final StationStatus status;
  final ManningType manningType;

  /// Daily windows during which an on-demand station is active.
  /// Empty for 24/7 stations.
  final List<TimeWindow> activeWindows;

  /// Certification IDs an assignee must ALL hold.
  final List<String> requiredCertifications;

  /// Org scope — only users matching every non-null layer may man the
  /// station. All-null = open to everyone.
  final Site? site;
  final Department? department;
  final JobRole? jobRole;
  final int capacity;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Station({
    required this.id,
    required this.name,
    this.status = StationStatus.active,
    this.manningType = ManningType.aroundTheClock,
    this.activeWindows = const [],
    this.requiredCertifications = const [],
    this.site,
    this.department,
    this.jobRole,
    this.capacity = 1,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  bool get isAroundTheClock => manningType == ManningType.aroundTheClock;

  factory Station.fromMap(String id, Map<String, dynamic> map) => Station(
        id: id,
        name: map['name'] as String? ?? '',
        status: StationStatus.fromString(map['status'] as String?),
        manningType: ManningType.fromString(map['manningType'] as String?),
        activeWindows: (map['activeWindows'] as List? ?? const [])
            .map((w) => TimeWindow.fromMap(Map<String, dynamic>.from(w as Map)))
            .toList(),
        requiredCertifications: List<String>.from(
            map['requiredCertifications'] as List? ?? const []),
        site: Site.fromString(map['site'] as String?),
        department: Department.fromString(map['department'] as String?),
        jobRole: JobRole.fromString(map['jobRole'] as String?),
        capacity: (map['capacity'] as num?)?.toInt() ?? 1,
        notes: map['notes'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );

  factory Station.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Station.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'name': name,
        'status': status.name,
        'manningType': manningType.wireName,
        'activeWindows': activeWindows.map((w) => w.toMap()).toList(),
        'requiredCertifications': requiredCertifications,
        if (site != null) 'site': site!.wireName,
        if (department != null) 'department': department!.name,
        if (jobRole != null) 'jobRole': jobRole!.name,
        'capacity': capacity,
        if (notes != null) 'notes': notes,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
        if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      };
}
