/// Station model representing a work station managed by Krizot.
///
/// Maps to the backend Station schema:
/// { id, name, location, capacity, status, notes, scheduleCount, createdAt, updatedAt }
library;

/// Operational status of a station.
enum StationStatus {
  active,
  closed;

  /// Parse from API string (case-insensitive).
  static StationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return StationStatus.active;
      case 'closed':
        return StationStatus.closed;
      default:
        return StationStatus.active;
    }
  }

  /// Serialise to the API string value.
  String toApiString() {
    switch (this) {
      case StationStatus.active:
        return 'active';
      case StationStatus.closed:
        return 'closed';
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

/// Immutable data class for a Krizot station.
class Station {
  const Station({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.status,
    this.notes,
    this.scheduleCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String location;
  final int capacity;
  final StationStatus status;
  final String? notes;
  final int scheduleCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Construct from a JSON map returned by the API.
  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      capacity: (json['capacity'] as num).toInt(),
      status: StationStatus.fromString((json['status'] as String?) ?? 'active'),
      notes: json['notes'] as String?,
      scheduleCount: (json['scheduleCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Serialise to a JSON map for API requests (create/update).
  Map<String, dynamic> toJson() => {
        'name': name,
        'location': location,
        'capacity': capacity,
        'status': status.toApiString(),
        if (notes != null) 'notes': notes,
      };

  /// Create a copy with optional field overrides.
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
      other is Station &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Station(id: $id, name: $name, location: $location, capacity: $capacity, status: $status)';
}

/// Stats returned by GET /api/stations/stats.
class StationStats {
  const StationStats({
    required this.total,
    required this.active,
    required this.closed,
    required this.totalCapacity,
  });

  final int total;
  final int active;
  final int closed;
  final int totalCapacity;

  factory StationStats.fromJson(Map<String, dynamic> json) {
    return StationStats(
      total: (json['total'] as num).toInt(),
      active: (json['active'] as num).toInt(),
      closed: (json['closed'] as num).toInt(),
      totalCapacity: (json['totalCapacity'] as num).toInt(),
    );
  }

  @override
  String toString() =>
      'StationStats(total: $total, active: $active, closed: $closed, totalCapacity: $totalCapacity)';
}
