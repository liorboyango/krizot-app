/// Station model representing a work station in the Krizot system.
///
/// Maps to the backend Station entity with full CRUD support.
library;

/// Represents the status of a station.
enum StationStatus {
  active,
  closed;

  /// Convert from API string value.
  static StationStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ACTIVE':
        return StationStatus.active;
      case 'CLOSED':
        return StationStatus.closed;
      default:
        return StationStatus.active;
    }
  }

  /// Convert to API string value.
  String toApiString() {
    switch (this) {
      case StationStatus.active:
        return 'ACTIVE';
      case StationStatus.closed:
        return 'CLOSED';
    }
  }

  /// Human-readable label.
  String get label {
    switch (this) {
      case StationStatus.active:
        return 'Active';
      case StationStatus.closed:
        return 'Closed';
    }
  }
}

/// Station data model.
class Station {
  final String id;
  final String name;
  final String location;
  final int capacity;
  final StationStatus status;
  final String? notes;
  final int scheduleCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Station({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.status,
    this.notes,
    this.scheduleCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a Station from a JSON map (API response).
  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      capacity: (json['capacity'] as num).toInt(),
      status: StationStatus.fromString(json['status'] as String? ?? 'ACTIVE'),
      notes: json['notes'] as String?,
      scheduleCount: (json['scheduleCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert to JSON map for API requests.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'capacity': capacity,
      'status': status.toApiString(),
      if (notes != null) 'notes': notes,
      'scheduleCount': scheduleCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  Station copyWith({
    String? id,
    String? name,
    String? location,
    int? capacity,
    StationStatus? status,
    String? notes,
    int? scheduleCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      scheduleCount: scheduleCount ?? this.scheduleCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Station && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Station(id: $id, name: $name, location: $location, capacity: $capacity, status: $status)';
}

/// Pagination metadata from API responses.
class PaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
    );
  }
}

/// Station stats from /api/stations/stats.
class StationStats {
  final int total;
  final int active;
  final int closed;
  final int totalCapacity;

  const StationStats({
    required this.total,
    required this.active,
    required this.closed,
    required this.totalCapacity,
  });

  factory StationStats.fromJson(Map<String, dynamic> json) {
    return StationStats(
      total: (json['total'] as num).toInt(),
      active: (json['active'] as num).toInt(),
      closed: (json['closed'] as num).toInt(),
      totalCapacity: (json['totalCapacity'] as num).toInt(),
    );
  }
}
