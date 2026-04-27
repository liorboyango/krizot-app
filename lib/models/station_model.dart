/// Data model for a Krizot station.
library;

/// Represents a physical station managed by the scheduler.
class StationModel {
  const StationModel({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.status,
    this.notes,
  });

  /// Unique station identifier (e.g. `ST-001`).
  final String id;

  /// Human-readable station name (e.g. `Alpha`).
  final String name;

  /// Physical location / sector (e.g. `North`).
  final String location;

  /// Maximum number of staff slots.
  final int capacity;

  /// Operational status.
  final StationStatus status;

  /// Optional free-text notes.
  final String? notes;

  /// Whether the station is currently operational.
  bool get isActive => status == StationStatus.active;

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  factory StationModel.fromJson(Map<String, dynamic> json) {
    return StationModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 1,
      status: StationStatus.fromString(json['status'] as String? ?? 'active'),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'capacity': capacity,
        'status': status.value,
        if (notes != null) 'notes': notes,
      };

  StationModel copyWith({
    String? id,
    String? name,
    String? location,
    int? capacity,
    StationStatus? status,
    String? notes,
  }) {
    return StationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'StationModel(id: $id, name: $name, location: $location, capacity: $capacity, status: ${status.value})';
}

/// Operational status of a station.
enum StationStatus {
  active('active'),
  closed('closed');

  const StationStatus(this.value);

  /// API string value.
  final String value;

  /// Parses a string from the API into a [StationStatus].
  static StationStatus fromString(String value) {
    return StationStatus.values.firstWhere(
      (s) => s.value == value.toLowerCase(),
      orElse: () => StationStatus.active,
    );
  }
}
