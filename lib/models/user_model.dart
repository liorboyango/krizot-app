/// Data model for an authenticated Krizot user.
library;

import 'dart:convert';

/// Represents a Krizot user returned by the API.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.name,
  });

  /// Unique user identifier.
  final String id;

  /// User's email address.
  final String email;

  /// RBAC role: `admin` or `manager`.
  final String role;

  /// Optional display name.
  final String? name;

  /// Whether this user has admin privileges.
  bool get isAdmin => role == 'admin';

  /// Display-friendly initials (up to 2 characters).
  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return name![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'manager',
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        if (name != null) 'name': name,
      };

  /// Serialise to a JSON string (for secure storage).
  String toJsonString() => jsonEncode(toJson());

  /// Deserialise from a JSON string (from secure storage).
  factory UserModel.fromJsonString(String jsonString) {
    return UserModel.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? role,
    String? name,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          role == other.role;

  @override
  int get hashCode => Object.hash(id, email, role);

  @override
  String toString() => 'UserModel(id: $id, email: $email, role: $role)';
}
