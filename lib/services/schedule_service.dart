/// Schedule service for the Krizot API.
///
/// Handles all CRUD operations for schedules:
/// - GET  /api/schedules              (list with filters)
/// - GET  /api/schedules/stats        (aggregate stats)
/// - GET  /api/schedules/week         (weekly grid)
/// - GET  /api/schedules/:id          (single schedule)
/// - POST /api/schedules              (create)
/// - PUT  /api/schedules/:id          (update)
/// - DELETE /api/schedules/:id        (delete, admin only)
/// - POST /api/schedules/assign       (bulk assign)
/// - POST /api/schedules/:id/unassign (unassign user)
library;

import 'package:dio/dio.dart';

import '../models/schedule.dart';
import '../models/api_response.dart';
import 'api_client.dart';

/// Query parameters for listing schedules.
class ScheduleListParams {
  const ScheduleListParams({
    this.stationId,
    this.userId,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.limit = 20,
  });

  final String? stationId;
  final String? userId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int limit;

  Map<String, dynamic> toQueryParameters() {
    return {
      'page': page,
      'limit': limit,
      if (stationId != null) 'stationId': stationId,
      if (userId != null) 'userId': userId,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
    };
  }
}

/// Payload for creating a new schedule.
class CreateScheduleRequest {
  const CreateScheduleRequest({
    required this.stationId,
    required this.startTime,
    required this.endTime,
    this.userId,
    this.notes,
  });

  final String stationId;
  final DateTime startTime;
  final DateTime endTime;
  final String? userId;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'stationId': stationId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        if (userId != null && userId!.isNotEmpty) 'userId': userId,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

/// Payload for updating an existing schedule (all fields optional).
class UpdateScheduleRequest {
  const UpdateScheduleRequest({
    this.stationId,
    this.userId,
    this.startTime,
    this.endTime,
    this.notes,
  });

  final String? stationId;
  final String? userId;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? notes;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (stationId != null) map['stationId'] = stationId;
    if (userId != null) map['userId'] = userId;
    if (startTime != null) map['startTime'] = startTime!.toIso8601String();
    if (endTime != null) map['endTime'] = endTime!.toIso8601String();
    if (notes != null) map['notes'] = notes;
    return map;
  }
}

/// Result of a bulk assign operation.
class BulkAssignResult {
  const BulkAssignResult({
    required this.succeeded,
    required this.failed,
    this.created,
    this.conflicts,
  });

  final List<Schedule> succeeded;
  final List<Map<String, dynamic>> failed;
  final List<Schedule>? created;
  final List<Map<String, dynamic>>? conflicts;

  factory BulkAssignResult.fromJson(Map<String, dynamic> json) {
    // Handle both response shapes from the two backend implementations
    final data = json['data'] as Map<String, dynamic>?;
    if (data != null) {
      // Shape 1: { succeeded: [...], failed: [...] }
      if (data.containsKey('succeeded')) {
        final succeeded = (data['succeeded'] as List<dynamic>? ?? [])
            .map((e) => Schedule.fromJson(e as Map<String, dynamic>))
            .toList();
        final failed = (data['failed'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
        return BulkAssignResult(succeeded: succeeded, failed: failed);
      }
      // Shape 2: { created: [...], conflicts: [...] }
      if (data.containsKey('created')) {
        final created = (data['created'] as List<dynamic>? ?? [])
            .map((e) => Schedule.fromJson(e as Map<String, dynamic>))
            .toList();
        final conflicts = (data['conflicts'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
        return BulkAssignResult(
          succeeded: created,
          failed: conflicts,
          created: created,
          conflicts: conflicts,
        );
      }
    }
    return const BulkAssignResult(succeeded: [], failed: []);
  }
}

/// Service for schedule-related API calls.
class ScheduleService {
  ScheduleService({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  // ---------------------------------------------------------------------------
  // List schedules
  // ---------------------------------------------------------------------------

  /// Fetch a paginated list of schedules with optional filters.
  ///
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<ApiListResponse<Schedule>> getSchedules([
    ScheduleListParams params = const ScheduleListParams(),
  ]) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/schedules',
        queryParameters: params.toQueryParameters(),
      );

      final body = response.data!;
      final dataList = body['data'] as List<dynamic>;
      final schedules = dataList
          .map((e) => Schedule.fromJson(e as Map<String, dynamic>))
          .toList();

      final paginationJson =
          (body['pagination'] as Map<String, dynamic>?) ??
              (body['meta'] as Map<String, dynamic>?) ??
              {'page': 1, 'limit': 20, 'total': schedules.length, 'totalPages': 1};

      return ApiListResponse(
        data: schedules,
        pagination: Pagination.fromJson(paginationJson),
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Schedule stats
  // ---------------------------------------------------------------------------

  /// Fetch aggregate schedule statistics.
  ///
  /// Optionally pass a [date] (ISO string) to get stats for a specific day.
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<ScheduleStats> getStats({String? date}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/schedules/stats',
        queryParameters: date != null ? {'date': date} : null,
      );
      final body = response.data!;
      final data = body['data'] as Map<String, dynamic>;
      return ScheduleStats.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Weekly grid
  // ---------------------------------------------------------------------------

  /// Fetch the weekly schedule grid.
  ///
  /// [weekStart] should be an ISO date string (e.g. '2024-04-27').
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<WeeklySchedule> getWeeklySchedule({String? weekStart}) async {
    try {
      // Try both endpoint paths used by the two backend implementations
      final path = '/schedules/week';
      final response = await _client.get<Map<String, dynamic>>(
        path,
        queryParameters: weekStart != null ? {'weekStart': weekStart} : null,
      );
      final body = response.data!;
      final data = body['data'] as Map<String, dynamic>;
      return WeeklySchedule.fromJson(data);
    } on DioException catch (e) {
      // Fallback to /weekly path
      if (e.response?.statusCode == 404) {
        try {
          final response = await _client.get<Map<String, dynamic>>(
            '/schedules/weekly',
            queryParameters:
                weekStart != null ? {'weekStart': weekStart} : null,
          );
          final body = response.data!;
          final data = body['data'] as Map<String, dynamic>;
          return WeeklySchedule.fromJson(data);
        } on DioException catch (e2) {
          throw ApiClient.parseError(e2);
        }
      }
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Single schedule
  // ---------------------------------------------------------------------------

  /// Fetch a single schedule by ID.
  ///
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<Schedule> getSchedule(String id) async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/schedules/$id');
      final body = response.data!;
      final data = body['data'] as Map<String, dynamic>;
      return Schedule.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Create schedule
  // ---------------------------------------------------------------------------

  /// Create a new schedule entry.
  ///
  /// Requires admin or manager role.
  /// Throws [ApiException] (409 for conflicts) or [NetworkException] on failure.
  Future<Schedule> createSchedule(CreateScheduleRequest request) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/schedules',
        data: request.toJson(),
      );
      final body = response.data!;
      final data = body['data'] as Map<String, dynamic>;
      return Schedule.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Update schedule
  // ---------------------------------------------------------------------------

  /// Update an existing schedule (partial update).
  ///
  /// Requires admin or manager role.
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<Schedule> updateSchedule(
    String id,
    UpdateScheduleRequest request,
  ) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/schedules/$id',
        data: request.toJson(),
      );
      final body = response.data!;
      final data = body['data'] as Map<String, dynamic>;
      return Schedule.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Delete schedule
  // ---------------------------------------------------------------------------

  /// Delete a schedule by ID.
  ///
  /// Requires admin role.
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<void> deleteSchedule(String id) async {
    try {
      await _client.delete<dynamic>('/schedules/$id');
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Bulk assign
  // ---------------------------------------------------------------------------

  /// Bulk assign users to schedules or create new schedule+assignment pairs.
  ///
  /// Requires admin or manager role.
  /// Returns a [BulkAssignResult] with succeeded and failed assignments.
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<BulkAssignResult> bulkAssign(
    List<AssignmentRequest> assignments,
  ) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/schedules/assign',
        data: {
          'assignments': assignments.map((a) => a.toJson()).toList(),
        },
      );
      return BulkAssignResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Unassign
  // ---------------------------------------------------------------------------

  /// Remove the user assignment from a schedule.
  ///
  /// Requires admin or manager role.
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<Schedule> unassign(String scheduleId) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/schedules/$scheduleId/unassign',
      );
      final body = response.data!;
      final data = body['data'] as Map<String, dynamic>;
      return Schedule.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
