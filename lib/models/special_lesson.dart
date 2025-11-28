class SpecialLesson {
  String id; // UUID
  DateTime date; // specific date this special lesson applies to
  int subjectId;
  int startHour;
  int startMinute;
  int endHour;
  int endMinute;
  String? originalLessonId; // optional reference to lesson being overridden
  String? notes;

  SpecialLesson({
    required this.id,
    required this.date,
    required this.subjectId,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.originalLessonId,
    this.notes,
  });
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'subjectId': subjectId,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'originalLessonId': originalLessonId,
      'notes': notes,
    };
  }

  factory SpecialLesson.fromJson(Map<String, dynamic> json) {
    return SpecialLesson(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      subjectId: json['subjectId'] as int,
      startHour: json['startHour'] as int,
      startMinute: json['startMinute'] as int,
      endHour: json['endHour'] as int,
      endMinute: json['endMinute'] as int,
      originalLessonId: json['originalLessonId'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
