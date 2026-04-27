/// Station data model matching backend API contract.
class StationModel {
  final String id;
  final String name;
  final String location;
  final int capacity;
  final String status;
  final String? notes;
  final int scheduleCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StationModel({
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

  factory StationModel.fromJson(Map<String, dynamic> json) {
    return StationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'active',
      notes: json['notes']?.toString(),
      scheduleCount: (json['scheduleCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'capacity': capacity,
        'status': status,
        if (notes != null) 'notes': notes,
      };

  bool get isActive => status.toLowerCase() == 'active';

  /// Formatted station ID for display (e.g., ST-001).
  String get displayId {
    final numPart = id.replaceAll(RegExp(r'[^0-9]'), '');
    if (numPart.isNotEmpty) {
      return 'ST-${numPart.padLeft(3, '0')}';
    }
    return 'ST-${id.substring(0, 3).toUpperCase()}';
  }

  StationModel copyWith({
    String? id,
    String? name,
    String? location,
    int? capacity,
    String? status,
    String? notes,
    int? scheduleCount,
  }) {
    return StationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      scheduleCount: scheduleCount ?? this.scheduleCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
