import 'package:dio/dio.dart';
import '../models/schedule.dart';
import '../utils/constants.dart';

/// Service for all schedule-related API calls
class ScheduleService {
  final Dio _dio;

  ScheduleService(this._dio);

  /// GET /api/schedules/week?weekStart=YYYY-MM-DD
  Future<WeeklySchedule> getWeeklySchedule(DateTime weekStart) async {
    final dateStr =
        '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    final response = await _dio.get(
      '${AppConstants.apiBaseUrl}/schedules/week',
      queryParameters: {'weekStart': dateStr},
    );
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      return WeeklySchedule.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['error']?['message'] ?? 'Failed to load weekly schedule');
  }

  /// GET /api/schedules/stats
  Future<ScheduleStats> getStats() async {
    final response = await _dio.get('${AppConstants.apiBaseUrl}/schedules/stats');
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      return ScheduleStats.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['error']?['message'] ?? 'Failed to load stats');
  }

  /// GET /api/schedules with optional filters
  Future<Map<String, dynamic>> getSchedules({
    String? stationId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (stationId != null) params['stationId'] = stationId;
    if (userId != null) params['userId'] = userId;
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();

    final response = await _dio.get(
      '${AppConstants.apiBaseUrl}/schedules',
      queryParameters: params,
    );
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      final schedules = (data['data'] as List<dynamic>)
          .map((s) => Schedule.fromJson(s as Map<String, dynamic>))
          .toList();
      return {
        'schedules': schedules,
        'pagination': data['pagination'],
      };
    }
    throw Exception(data['error']?['message'] ?? 'Failed to load schedules');
  }

  /// POST /api/schedules — create a new shift
  Future<Schedule> createSchedule({
    required String stationId,
    String? userId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'stationId': stationId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
    if (userId != null) body['userId'] = userId;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final response = await _dio.post(
      '${AppConstants.apiBaseUrl}/schedules',
      data: body,
    );
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      return Schedule.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['error']?['message'] ?? 'Failed to create schedule');
  }

  /// PUT /api/schedules/:id — update a shift
  Future<Schedule> updateSchedule(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final response = await _dio.put(
      '${AppConstants.apiBaseUrl}/schedules/$id',
      data: updates,
    );
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      return Schedule.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['error']?['message'] ?? 'Failed to update schedule');
  }

  /// DELETE /api/schedules/:id
  Future<void> deleteSchedule(String id) async {
    final response =
        await _dio.delete('${AppConstants.apiBaseUrl}/schedules/$id');
    final data = response.data as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['error']?['message'] ?? 'Failed to delete schedule');
    }
  }

  /// POST /api/schedules/assign — bulk assign staff to shifts
  Future<Map<String, dynamic>> assignSchedules(
    List<Map<String, dynamic>> assignments,
  ) async {
    final response = await _dio.post(
      '${AppConstants.apiBaseUrl}/schedules/assign',
      data: {'assignments': assignments},
    );
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception(data['error']?['message'] ?? 'Failed to assign schedules');
  }

  /// POST /api/schedules/:id/unassign
  Future<Schedule> unassignSchedule(String id) async {
    final response = await _dio.post(
      '${AppConstants.apiBaseUrl}/schedules/$id/unassign',
    );
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      return Schedule.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['error']?['message'] ?? 'Failed to unassign schedule');
  }
}
