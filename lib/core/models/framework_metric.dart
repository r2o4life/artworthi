class FrameworkMetric {
  final String id;
  final String name;
  final String description;
  final double value;
  final double min;
  final double max;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FrameworkMetric({
    required this.id,
    required this.name,
    required this.description,
    required this.value,
    required this.min,
    required this.max,
    required this.createdAt,
    required this.updatedAt,
  });

  FrameworkMetric copyWith({
    String? id,
    String? name,
    String? description,
    double? value,
    double? min,
    double? max,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FrameworkMetric(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    value: value ?? this.value,
    min: min ?? this.min,
    max: max ?? this.max,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'value': value,
    'min': min,
    'max': max,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  static FrameworkMetric fromJson(Map<String, dynamic> json) => FrameworkMetric(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    value: (json['value'] as num).toDouble(),
    min: (json['min'] as num).toDouble(),
    max: (json['max'] as num).toDouble(),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}
