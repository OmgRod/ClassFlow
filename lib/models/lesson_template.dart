class LessonTemplate {
  String id; // UUID
  String name;
  String? description;
  List<TemplateLessonEntry> lessons;
  DateTime createdAt;
  DateTime? lastUsedAt;

  LessonTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.lessons,
    DateTime? createdAt,
    this.lastUsedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'lessons': lessons.map((l) => l.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  factory LessonTemplate.fromJson(Map<String, dynamic> json) {
    return LessonTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      lessons: (json['lessons'] as List)
          .map((l) => TemplateLessonEntry.fromJson(l as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
    );
  }

  LessonTemplate copyWith({
    String? id,
    String? name,
    String? description,
    List<TemplateLessonEntry>? lessons,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return LessonTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      lessons: lessons ?? this.lessons,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return 'LessonTemplate(id: $id, name: $name, ${lessons.length} lessons)';
  }
}

class TemplateLessonEntry {
  int subjectId;
  int dayOfWeek; // 1 = Monday, 7 = Sunday
  int startHour;
  int startMinute;
  int endHour;
  int endMinute;
  String? notes;
  int weekNumber; // 0 = every week, 1 = week 1, 2 = week 2

  TemplateLessonEntry({
    required this.subjectId,
    required this.dayOfWeek,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.notes,
    this.weekNumber = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'subjectId': subjectId,
      'dayOfWeek': dayOfWeek,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'notes': notes,
      'weekNumber': weekNumber,
    };
  }

  factory TemplateLessonEntry.fromJson(Map<String, dynamic> json) {
    return TemplateLessonEntry(
      subjectId: json['subjectId'] as int,
      dayOfWeek: json['dayOfWeek'] as int,
      startHour: json['startHour'] as int,
      startMinute: json['startMinute'] as int,
      endHour: json['endHour'] as int,
      endMinute: json['endMinute'] as int,
      notes: json['notes'] as String?,
      weekNumber: json['weekNumber'] as int? ?? 0,
    );
  }

  /// Get formatted start time
  String get formattedStartTime {
    return '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
  }

  /// Get formatted end time
  String get formattedEndTime {
    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }

  /// Get duration in minutes
  int get durationMinutes {
    return (endHour * 60 + endMinute) - (startHour * 60 + startMinute);
  }
}
