/// "N holders of certification X" — the building block for daily manning
/// requirements and for a certification's simulation staffing definition.
class CertRequirement {
  final String certificationId;
  final int count;

  const CertRequirement({required this.certificationId, required this.count});

  factory CertRequirement.fromMap(Map<String, dynamic> map) => CertRequirement(
        certificationId: map['certificationId'] as String? ?? '',
        count: (map['count'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toMap() => {
        'certificationId': certificationId,
        'count': count,
      };

  static List<CertRequirement> listFromMaps(List? maps) =>
      (maps ?? const [])
          .map((m) =>
              CertRequirement.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList();

  static List<Map<String, dynamic>> listToMaps(List<CertRequirement> list) =>
      list.map((r) => r.toMap()).toList();
}
