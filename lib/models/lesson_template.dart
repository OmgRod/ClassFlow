import 'package:hive/hive.dart';

part 'lesson_template.g.dart';

@HiveType(typeId: 4)
class LessonTemplate extends HiveObject {
  @HiveField(0)
  String id; // UUID

  @HiveField(1)
  String name;

  @HiveField(2)
  int startHour;

  @HiveField(3)
  int startMinute;

  @HiveField(4)
  int endHour;

  @HiveField(5)
  int endMinute;

  @HiveField(6)
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
}
