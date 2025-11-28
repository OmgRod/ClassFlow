class LessonTemplate {
  String id; // UUID
  String name;
  int startHour;
  int startMinute;
  int endHour;
  int endMinute;
  String? description;

  LessonTemplate({
    required this.id,
    required this.name,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.description,
  });

  /// Get duration in minutes
  int get durationMinutes {
    return (endHour * 60 + endMinute) - (startHour * 60 + startMinute);
  }

  /// Format time as HH:MM
  String get formattedStartTime {
    return '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
  }

  String get formattedEndTime {
    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }

  LessonTemplate copyWith({
    String? id,
    String? name,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    String? description,
  }) {
    return LessonTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'LessonTemplate(id: $id, name: $name, $formattedStartTime-$formattedEndTime)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'description': description,
    };
  }

  factory LessonTemplate.fromJson(Map<String, dynamic> json) {
    return LessonTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      startHour: json['startHour'] as int,
      startMinute: json['startMinute'] as int,
      endHour: json['endHour'] as int,
      endMinute: json['endMinute'] as int,
      description: json['description'] as String?,
    );
  }
}
