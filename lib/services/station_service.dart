/// Station service for the Krizot API.
///
/// Handles all CRUD operations for stations:
/// - GET  /api/stations          (list with pagination/filtering)
/// - GET  /api/stations/stats    (aggregate stats)
/// - GET  /api/stations/:id      (single station with schedules)
/// - POST /api/stations          (create)
/// - PUT  /api/stations/:id      (update)
/// - DELETE /api/stations/:id    (delete, admin only)
library;

import 'package:dio/dio.dart';

import '../models/station.dart';
import '../models/api_response.dart';
import 'api_client.dart';

/// Query parameters for listing stations.
class StationListParams {
  const StationListParams({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.status,
    this.sortBy,
    this.sortOrder,
  });

  final int page;
  final int limit;
  final String? search;
  final StationStatus? status;
  final String? sortBy;
  final String? sortOrder;

  Map<String, dynamic> toQueryParameters() {
    return {
      'page': page,
      'limit': limit,
      if (search != null && search!.isNotEmpty) 'search': search,
      if (status != null) 'status': status!.toApiString(),
      if (sortBy != null) 'sortBy': sortBy,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };
  }
}

/// Payload for creating a new station.
class CreateStationRequest {
  const CreateStationRequest({
    required this.name,
    required this.location,
    required this.capacity,
    this.status = StationStatus.active,
    this.notes,
  });

  final String name;
  final String location;
  final int capacity;
  final StationStatus status;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        'location': location,
        'capacity': capacity,
        'status': status.toApiString(),
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

/// Payload for updating an existing station (all fields optional).
class UpdateStationRequest {
  const UpdateStationRequest({
    this.name,
    this.location,
    this.capacity,
    this.status,
    this.notes,
  });

  final String? name;
  final String? location;
  final int? capacity;
  final StationStatus? status;
  final String? notes;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (location != null) map['location'] = location;
    if (capacity != null) map['capacity'] = capacity;
    if (status != null) map['status'] = status!.toApiString();
    if (notes != null) map['notes'] = notes;
    return map;
  }
}

/// Service for station-related API calls.
class StationService {
  StationService({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  // ---------------------------------------------------------------------------
  // List stations
  // ---------------------------------------------------------------------------

  /// Fetch a paginated list of stations.
  ///
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<ApiListResponse<Station>> getStations([
    StationListParams params = const StationListParams(),
  ]) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/stations',
        queryParameters: params.toQueryParameters(),
      );

      final body = response.data!;
      final dataList = body['data'] as List<dynamic>;
      final stations =
          dataList.map((e) => Station.fromJson(e as Map<String, dynamic>)).toList();

      final paginationJson =
          (body['pagination'] as Map<String, dynamic>?) ??
              (body['meta'] as Map<String, dynamic>?) ??
              {'page': 1, 'limit': 20, 'total': stations.length, 'totalPages': 1};

      return ApiListResponse(
        data: stations,
        pagination: Pagination.fromJson(paginationJson),
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Station stats
  // ---------------------------------------------------------------------------

  /// Fetch aggregate station statistics.
  ///
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<StationStats> getStats() async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/stations/stats');
      final body = response.data!;
      final data = body['data'] as Map<String, dynamic>;
      return StationStats.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Single station
  // ---------------------------------------------------------------------------

  /// Fetch a single station by ID (includes nested schedules).
  ///
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<Station> getStation(String id) async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/stations/$id');
      final body = response.data!;
      final data = body['data'] as Map<String, dynamic>;
      return Station.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Create station
  // ---------------------------------------------------------------------------

  /// Create a new station.
  ///
  /// Requires admin or manager role.
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<Station> createStation(CreateStationRequest request) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/stations',
        data: request.toJson(),
      );
      final body = response.data!;
      final data = body['data'] as Map<String, dynamic>;
      return Station.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Update station
  // ---------------------------------------------------------------------------

  /// Update an existing station (partial update).
  ///
  /// Requires admin or manager role.
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<Station> updateStation(
    String id,
    UpdateStationRequest request,
  ) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/stations/$id',
        data: request.toJson(),
      );
      final body = response.data!;
      final data = body['data'] as Map<String, dynamic>;
      return Station.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Delete station
  // ---------------------------------------------------------------------------

  /// Delete a station by ID.
  ///
  /// Requires admin role.
  /// Pass [force] = true to bypass active schedule check.
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<void> deleteStation(String id, {bool force = false}) async {
    try {
      await _client.delete<dynamic>(
        '/stations/$id',
        queryParameters: force ? {'force': 'true'} : null,
      );
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
