import 'package:dio/dio.dart';
import '../models/schedule_model.dart';
import 'api_client.dart';

/// Service for fetching dashboard statistics and today's schedules.
class DashboardService {
  final ApiClient _client;

  DashboardService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  /// Fetches dashboard stats from /api/schedules/stats.
  Future<DashboardStats> getStats({String? date}) async {
    try {
      final response = await _client.dio.get(
        '/schedules/stats',
        queryParameters: date != null ? {'date': date} : null,
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return DashboardStats.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to load dashboard stats');
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data['error']?['message']?.toString() ?? 'Failed to load data';
      }
    } catch (_) {}
    return 'Network error. Please try again.';
  }
}
