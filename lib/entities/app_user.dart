import 'package:cloud_firestore/cloud_firestore.dart';

import 'org_scope.dart';

export 'org_scope.dart';

/// Role hierarchy. The Firebase custom claim is authoritative; the Firestore
/// `users/{uid}.role` field mirrors it for UI and queries.
enum UserRole {
  admin,
  manager,
  dispatcher,
  employee;

  static UserRole fromString(String? value) => UserRole.values.firstWhere(
        (role) => role.name == value,
        orElse: () => UserRole.employee,
      );

  bool get canManage => this == UserRole.admin || this == UserRole.manager;
  bool get canDispatch => this == UserRole.admin || this == UserRole.dispatcher;
}

enum UserStatus {
  available,
  sick,
  unavailable;

  static UserStatus fromString(String? value) => UserStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => UserStatus.available,
      );
}

class AppUser {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final UserRole role;
  final List<String> certifications;

  /// When each held certification was earned: certId → timestamp.
  final Map<String, DateTime> certificationTimes;

  /// The fixed common training course the user belongs to — ascending
  /// order, so a lower number means an earlier (more senior) cohort.
  final int? courseNumber;

  /// Organizational placement; null while unassigned.
  final Site? site;
  final Department? department;
  final JobRole? jobRole;
  final UserStatus status;
  final Map<String, dynamic> fcmTokens;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.role = UserRole.employee,
    this.certifications = const [],
    this.certificationTimes = const {},
    this.courseNumber,
    this.site,
    this.department,
    this.jobRole,
    this.status = UserStatus.available,
    this.fcmTokens = const {},
    this.createdAt,
    this.updatedAt,
  });

  bool get isAvailable => status == UserStatus.available;

  bool hasAllCertifications(List<String> required) =>
      required.every(certifications.contains);

  /// Whether the user satisfies an org scope (of a station or a
  /// certification). A null scope layer is a wildcard.
  bool matchesScope({Site? site, Department? department, JobRole? jobRole}) =>
      (site == null || this.site == site) &&
      (department == null || this.department == department) &&
      (jobRole == null || this.jobRole == jobRole);

  DateTime? certificationEarnedAt(String certId) => certificationTimes[certId];

  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
        id: id,
        displayName: map['displayName'] as String? ?? '',
        email: map['email'] as String? ?? '',
        photoUrl: map['photoUrl'] as String?,
        role: UserRole.fromString(map['role'] as String?),
        certifications:
            List<String>.from(map['certifications'] as List? ?? const []),
        certificationTimes:
            (map['certificationTimes'] as Map? ?? const {}).map((key, value) =>
                MapEntry(key as String, (value as Timestamp).toDate())),
        courseNumber: (map['courseNumber'] as num?)?.toInt(),
        site: Site.fromString(map['site'] as String?),
        department: Department.fromString(map['department'] as String?),
        jobRole: JobRole.fromString(map['jobRole'] as String?),
        status: UserStatus.fromString(map['status'] as String?),
        fcmTokens: Map<String, dynamic>.from(map['fcmTokens'] as Map? ?? {}),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AppUser.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'role': role.name,
        'certifications': certifications,
        'certificationTimes': certificationTimes.map(
            (key, value) => MapEntry(key, Timestamp.fromDate(value))),
        if (courseNumber != null) 'courseNumber': courseNumber,
        if (site != null) 'site': site!.wireName,
        if (department != null) 'department': department!.name,
        if (jobRole != null) 'jobRole': jobRole!.name,
        'status': status.name,
        'fcmTokens': fcmTokens,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
        if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      };

  AppUser copyWith({
    String? displayName,
    UserRole? role,
    List<String>? certifications,
    Map<String, DateTime>? certificationTimes,
    int? courseNumber,
    Site? site,
    Department? department,
    JobRole? jobRole,
    UserStatus? status,
  }) =>
      AppUser(
        id: id,
        displayName: displayName ?? this.displayName,
        email: email,
        photoUrl: photoUrl,
        role: role ?? this.role,
        certifications: certifications ?? this.certifications,
        certificationTimes: certificationTimes ?? this.certificationTimes,
        courseNumber: courseNumber ?? this.courseNumber,
        site: site ?? this.site,
        department: department ?? this.department,
        jobRole: jobRole ?? this.jobRole,
        status: status ?? this.status,
        fcmTokens: fcmTokens,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
