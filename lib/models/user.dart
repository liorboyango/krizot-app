/// User model representing an authenticated user or staff member.
///
/// Maps to the backend User schema:
/// { id, email, name, role }
library;

/// Roles supported by the Krizot platform.
enum UserRole {
  admin,
  manager;

  /// Parse a role string from the API.
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      default:
        return UserRole.manager;
    }
  }

  /// Serialise to the API string value.
  String toApiString() {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.manager:
        return 'MANAGER';
    }
  }

  /// Human-readable label.
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
    }
  }
}

/// Immutable data class for a Krizot user.
class User {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  final String id;
  final String email;
  final String name;
  final UserRole role;

  /// Construct from a JSON map returned by the API.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: (json['name'] as String?) ?? '',
      role: UserRole.fromString((json['role'] as String?) ?? 'manager'),
    );
  }

  /// Serialise to a JSON map for API requests.
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role.toApiString(),
      };

  /// Create a copy with optional field overrides.
  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          role == other.role;

  @override
  int get hashCode => Object.hash(id, email, name, role);

  @override
  String toString() => 'User(id: $id, email: $email, name: $name, role: $role)';
}
