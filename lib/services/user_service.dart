/// User service for the Krizot API.
///
/// Handles CRUD operations for users (staff management):
/// - GET  /api/users          (list)
/// - GET  /api/users/:id      (single)
/// - POST /api/users          (create, admin only)
/// - PUT  /api/users/:id      (update, admin only)
/// - DELETE /api/users/:id    (delete, admin only)
library;

import 'package:dio/dio.dart';

import '../models/user.dart';
import '../models/api_response.dart';
import 'api_client.dart';

/// Query parameters for listing users.
class UserListParams {
  const UserListParams({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.role,
  });

  final int page;
  final int limit;
  final String? search;
  final UserRole? role;

  Map<String, dynamic> toQueryParameters() => {
        'page': page,
        'limit': limit,
        if (search != null && search!.isNotEmpty) 'search': search,
        if (role != null) 'role': role!.toApiString(),
      };
}

/// Payload for creating a new user.
class CreateUserRequest {
  const CreateUserRequest({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });

  final String email;
  final String password;
  final String name;
  final UserRole role;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'name': name,
        'role': role.toApiString(),
      };
}

/// Payload for updating an existing user.
class UpdateUserRequest {
  const UpdateUserRequest({
    this.email,
    this.name,
    this.role,
    this.password,
  });

  final String? email;
  final String? name;
  final UserRole? role;
  final String? password;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (email != null) map['email'] = email;
    if (name != null) map['name'] = name;
    if (role != null) map['role'] = role!.toApiString();
    if (password != null && password!.isNotEmpty) map['password'] = password;
    return map;
  }
}

/// Service for user/staff management API calls.
class UserService {
  UserService({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  // ---------------------------------------------------------------------------
  // List users
  // ---------------------------------------------------------------------------

  /// Fetch a paginated list of users.
  ///
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<ApiListResponse<User>> getUsers([
    UserListParams params = const UserListParams(),
  ]) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/users',
        queryParameters: params.toQueryParameters(),
      );

      final body = response.data!;
      final dataList = body['data'] as List<dynamic>;
      final users =
          dataList.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();

      final paginationJson =
          (body['pagination'] as Map<String, dynamic>?) ??
              (body['meta'] as Map<String, dynamic>?) ??
              {'page': 1, 'limit': 20, 'total': users.length, 'totalPages': 1};

      return ApiListResponse(
        data: users,
        pagination: Pagination.fromJson(paginationJson),
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Single user
  // ---------------------------------------------------------------------------

  /// Fetch a single user by ID.
  ///
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<User> getUser(String id) async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/users/$id');
      final body = response.data!;
      final data = body['data'] as Map<String, dynamic>;
      return User.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Create user
  // ---------------------------------------------------------------------------

  /// Create a new user. Requires admin role.
  ///
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<User> createUser(CreateUserRequest request) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/users',
        data: request.toJson(),
      );
      final body = response.data!;
      final data = body['data'] as Map<String, dynamic>;
      return User.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Update user
  // ---------------------------------------------------------------------------

  /// Update an existing user. Requires admin role.
  ///
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<User> updateUser(String id, UpdateUserRequest request) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/users/$id',
        data: request.toJson(),
      );
      final body = response.data!;
      final data = body['data'] as Map<String, dynamic>;
      return User.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Delete user
  // ---------------------------------------------------------------------------

  /// Delete a user by ID. Requires admin role.
  ///
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<void> deleteUser(String id) async {
    try {
      await _client.delete<dynamic>('/users/$id');
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
