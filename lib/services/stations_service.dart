import 'package:dio/dio.dart';
import '../models/station.dart';
import '../utils/constants.dart';
import 'api_client.dart';

/// Service for station CRUD operations via the Krizot REST API.
///
/// All methods require a valid JWT token (handled by [ApiClient] interceptor).
class StationsService {
  final ApiClient _client;

  StationsService({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  /// Fetch a paginated list of stations.
  ///
  /// Supports optional [search], [status], [page], [limit], [sortBy], [sortOrder].
  Future<StationsPage> getStations({
    String? search,
    String? status,
    int page = 1,
    int limit = AppConstants.defaultPageSize,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final response = await _client.get<Map<String, dynamic>>(
        '/stations',
        queryParameters: queryParams,
      );

      final body = response.data!;
      _assertSuccess(body);

      final dataList = (body['data'] as List<dynamic>)
          .map((e) => Station.fromJson(e as Map<String, dynamic>))
          .toList();

      final paginationJson =
          body['pagination'] as Map<String, dynamic>? ?? {};
      final pagination = PaginationMeta(
        page: (paginationJson['page'] as num?)?.toInt() ?? page,
        limit: (paginationJson['limit'] as num?)?.toInt() ?? limit,
        total: (paginationJson['total'] as num?)?.toInt() ?? dataList.length,
        totalPages:
            (paginationJson['totalPages'] as num?)?.toInt() ?? 1,
      );

      return StationsPage(stations: dataList, pagination: pagination);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Fetch station statistics.
  Future<StationStats> getStats() async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/stations/stats');
      final body = response.data!;
      _assertSuccess(body);
      return StationStats.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Fetch a single station by ID.
  Future<Station> getStation(String id) async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/stations/$id');
      final body = response.data!;
      _assertSuccess(body);
      return Station.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Create a new station.
  Future<Station> createStation(CreateStationRequest request) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/stations',
        data: request.toJson(),
      );
      final body = response.data!;
      _assertSuccess(body);
      return Station.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Update an existing station.
  Future<Station> updateStation(
      String id, UpdateStationRequest request) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/stations/$id',
        data: request.toJson(),
      );
      final body = response.data!;
      _assertSuccess(body);
      return Station.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Delete a station by ID.
  ///
  /// Set [force] to true to bypass active schedule check (admin only).
  Future<void> deleteStation(String id, {bool force = false}) async {
    try {
      final response = await _client.delete<Map<String, dynamic>>(
        '/stations/$id',
        queryParameters: force ? {'force': 'true'} : null,
      );
      final body = response.data!;
      _assertSuccess(body);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  void _assertSuccess(Map<String, dynamic> body) {
    if (body['success'] != true) {
      final error = body['error'] as Map<String, dynamic>?;
      throw StationServiceException(
        error?['message'] as String? ?? 'Operation failed',
        code: error?['code'] as String?,
      );
    }
  }

  StationServiceException _mapError(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final error = data['error'] as Map<String, dynamic>?;
        return StationServiceException(
          error?['message'] as String? ??
              data['message'] as String? ??
              'Request failed',
          code: error?['code'] as String?,
          statusCode: e.response?.statusCode,
        );
      }
    } catch (_) {}
    return StationServiceException(
      e.message ?? 'Network error',
      statusCode: e.response?.statusCode,
    );
  }
}

/// Paginated stations response.
class StationsPage {
  final List<Station> stations;
  final PaginationMeta pagination;

  const StationsPage({
    required this.stations,
    required this.pagination,
  });
}

/// Request body for creating a station.
class CreateStationRequest {
  final String name;
  final String location;
  final int capacity;
  final String status;
  final String? notes;

  const CreateStationRequest({
    required this.name,
    required this.location,
    required this.capacity,
    this.status = 'ACTIVE',
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'location': location,
        'capacity': capacity,
        'status': status,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

/// Request body for updating a station (all fields optional).
class UpdateStationRequest {
  final String? name;
  final String? location;
  final int? capacity;
  final String? status;
  final String? notes;

  const UpdateStationRequest({
    this.name,
    this.location,
    this.capacity,
    this.status,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (location != null) map['location'] = location;
    if (capacity != null) map['capacity'] = capacity;
    if (status != null) map['status'] = status;
    if (notes != null) map['notes'] = notes;
    return map;
  }
}

/// Exception thrown by [StationsService].
class StationServiceException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const StationServiceException(
    this.message, {
    this.code,
    this.statusCode,
  });

  @override
  String toString() => 'StationServiceException: $message (code: $code, status: $statusCode)';
}
