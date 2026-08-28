import 'package:cloud_firestore/cloud_firestore.dart';

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
    this.status = UserStatus.available,
    this.fcmTokens = const {},
    this.createdAt,
    this.updatedAt,
  });

  bool get isAvailable => status == UserStatus.available;

  bool hasAllCertifications(List<String> required) =>
      required.every(certifications.contains);

  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
        id: id,
        displayName: map['displayName'] as String? ?? '',
        email: map['email'] as String? ?? '',
        photoUrl: map['photoUrl'] as String?,
        role: UserRole.fromString(map['role'] as String?),
        certifications:
            List<String>.from(map['certifications'] as List? ?? const []),
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
        'status': status.name,
        'fcmTokens': fcmTokens,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
        if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      };

  AppUser copyWith({
    String? displayName,
    UserRole? role,
    List<String>? certifications,
    UserStatus? status,
  }) =>
      AppUser(
        id: id,
        displayName: displayName ?? this.displayName,
        email: email,
        photoUrl: photoUrl,
        role: role ?? this.role,
        certifications: certifications ?? this.certifications,
        status: status ?? this.status,
        fcmTokens: fcmTokens,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
