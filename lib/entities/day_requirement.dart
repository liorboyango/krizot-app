import 'package:cloud_firestore/cloud_firestore.dart';

import 'cert_requirement.dart';

/// The manning definition for one calendar day: exactly how many holders of
/// which certifications must be on shift. Doc id == [dayKey].
class DayRequirement {
  /// 'YYYY-MM-DD', matches `shifts.dayKey`.
  final String dayKey;
  final List<CertRequirement> requirements;
  final String? lastModifiedBy;
  final DateTime? lastModifiedAt;

  const DayRequirement({
    required this.dayKey,
    this.requirements = const [],
    this.lastModifiedBy,
    this.lastModifiedAt,
  });

  factory DayRequirement.fromMap(String id, Map<String, dynamic> map) =>
      DayRequirement(
        dayKey: map['dayKey'] as String? ?? id,
        requirements: CertRequirement.listFromMaps(map['requirements'] as List?),
        lastModifiedBy: map['lastModifiedBy'] as String?,
        lastModifiedAt: (map['lastModifiedAt'] as Timestamp?)?.toDate(),
      );

  factory DayRequirement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      DayRequirement.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'dayKey': dayKey,
        'requirements': CertRequirement.listToMaps(requirements),
        if (lastModifiedBy != null) 'lastModifiedBy': lastModifiedBy,
        if (lastModifiedAt != null)
          'lastModifiedAt': Timestamp.fromDate(lastModifiedAt!),
      };
}
