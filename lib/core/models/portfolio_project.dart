class PortfolioProject {
  final String id;
  final String name;
  final String tagline;
  final String domain;
  final List<String> bullets;
  final List<String> primitives;
  final List<ProjectMilestone> milestones;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PortfolioProject({
    required this.id,
    required this.name,
    required this.tagline,
    required this.domain,
    required this.bullets,
    required this.primitives,
    required this.milestones,
    required this.createdAt,
    required this.updatedAt,
  });

  PortfolioProject copyWith({
    String? id,
    String? name,
    String? tagline,
    String? domain,
    List<String>? bullets,
    List<String>? primitives,
    List<ProjectMilestone>? milestones,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PortfolioProject(
    id: id ?? this.id,
    name: name ?? this.name,
    tagline: tagline ?? this.tagline,
    domain: domain ?? this.domain,
    bullets: bullets ?? this.bullets,
    primitives: primitives ?? this.primitives,
    milestones: milestones ?? this.milestones,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tagline': tagline,
    'domain': domain,
    'bullets': bullets,
    'primitives': primitives,
    'milestones': milestones.map((m) => m.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  static PortfolioProject fromJson(Map<String, dynamic> json) => PortfolioProject(
    id: json['id'] as String,
    name: json['name'] as String,
    tagline: json['tagline'] as String,
    domain: json['domain'] as String,
    bullets: (json['bullets'] as List).cast<String>(),
    primitives: (json['primitives'] as List).cast<String>(),
    milestones: (json['milestones'] as List)
        .cast<Map<String, dynamic>>()
        .map(ProjectMilestone.fromJson)
        .toList(),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

class ProjectMilestone {
  final String id;
  final String title;
  final String phase;
  final String description;
  final int week;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectMilestone({
    required this.id,
    required this.title,
    required this.phase,
    required this.description,
    required this.week,
    required this.createdAt,
    required this.updatedAt,
  });

  ProjectMilestone copyWith({
    String? id,
    String? title,
    String? phase,
    String? description,
    int? week,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProjectMilestone(
    id: id ?? this.id,
    title: title ?? this.title,
    phase: phase ?? this.phase,
    description: description ?? this.description,
    week: week ?? this.week,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'phase': phase,
    'description': description,
    'week': week,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  static ProjectMilestone fromJson(Map<String, dynamic> json) => ProjectMilestone(
    id: json['id'] as String,
    title: json['title'] as String,
    phase: json['phase'] as String,
    description: json['description'] as String,
    week: (json['week'] as num).toInt(),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}
