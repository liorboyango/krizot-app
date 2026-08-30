import 'package:cloud_firestore/cloud_firestore.dart';

import 'cert_requirement.dart';

/// A skill/qualification from the catalog. Stations require certifications,
/// users hold them, and emergency event types target holders of them
/// (e.g. "Type C Responder" is just a certification).
class Certification {
  final String id;
  final String name;
  final String? description;

  /// Seniority/importance rank — the default priority of training sessions
  /// toward this certification (higher level = higher priority).
  final int level;

  /// Staffing needed to run a simulation for this certification:
  /// how many holders of which certifications.
  final List<CertRequirement> simulationStaff;

  /// Hex color (e.g. '#0D7CFF') for chips in the UI.
  final String? color;
  final DateTime? createdAt;

  const Certification({
    required this.id,
    required this.name,
    this.description,
    this.level = 0,
    this.simulationStaff = const [],
    this.color,
    this.createdAt,
  });

  factory Certification.fromMap(String id, Map<String, dynamic> map) =>
      Certification(
        id: id,
        name: map['name'] as String? ?? '',
        description: map['description'] as String?,
        level: (map['level'] as num?)?.toInt() ?? 0,
        simulationStaff:
            CertRequirement.listFromMaps(map['simulationStaff'] as List?),
        color: map['color'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  factory Certification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Certification.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'name': name,
        if (description != null) 'description': description,
        'level': level,
        'simulationStaff': CertRequirement.listToMaps(simulationStaff),
        if (color != null) 'color': color,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      };

  Certification copyWith({
    String? name,
    int? level,
    List<CertRequirement>? simulationStaff,
  }) =>
      Certification(
        id: id,
        name: name ?? this.name,
        description: description,
        level: level ?? this.level,
        simulationStaff: simulationStaff ?? this.simulationStaff,
        color: color,
        createdAt: createdAt,
      );
}
