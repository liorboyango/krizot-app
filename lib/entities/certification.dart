import 'package:cloud_firestore/cloud_firestore.dart';

/// A skill/qualification from the catalog. Stations require certifications,
/// users hold them, and emergency event types target holders of them
/// (e.g. "Type C Responder" is just a certification).
class Certification {
  final String id;
  final String name;
  final String? description;

  /// Hex color (e.g. '#0D7CFF') for chips in the UI.
  final String? color;
  final DateTime? createdAt;

  const Certification({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.createdAt,
  });

  factory Certification.fromMap(String id, Map<String, dynamic> map) =>
      Certification(
        id: id,
        name: map['name'] as String? ?? '',
        description: map['description'] as String?,
        color: map['color'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  factory Certification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Certification.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'name': name,
        if (description != null) 'description': description,
        if (color != null) 'color': color,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      };
}
