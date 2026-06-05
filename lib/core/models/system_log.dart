class SystemLog {
  final String id;
  final String channel;
  final String message;
  final LogSeverity severity;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SystemLog({
    required this.id,
    required this.channel,
    required this.message,
    required this.severity,
    required this.createdAt,
    required this.updatedAt,
  });

  SystemLog copyWith({
    String? id,
    String? channel,
    String? message,
    LogSeverity? severity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SystemLog(
    id: id ?? this.id,
    channel: channel ?? this.channel,
    message: message ?? this.message,
    severity: severity ?? this.severity,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'channel': channel,
    'message': message,
    'severity': severity.name,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  static SystemLog fromJson(Map<String, dynamic> json) => SystemLog(
    id: json['id'] as String,
    channel: json['channel'] as String,
    message: json['message'] as String,
    severity: LogSeverity.values.firstWhere((e) => e.name == json['severity']),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

enum LogSeverity { info, ok, warn, err }
