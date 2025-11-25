import 'package:hive/hive.dart';

part 'lesson.g.dart';

@HiveType(typeId: 2)
class Lesson extends HiveObject {
  @HiveField(0)
  String id; // UUID

  @HiveField(1)
  int subjectId;

  @HiveField(2)
  int dayOfWeek; // 1 = Monday, 7 = Sunday

  @HiveField(3)
  int startHour;

  @HiveField(4)
  int startMinute;

  @HiveField(5)
  int endHour;

  @HiveField(6)
  int endMinute;

  @HiveField(7)
  RecurrenceType recurrenceType;

  @HiveField(8)
  int? customIntervalWeeks; // For custom recurrence

  @HiveField(9)
  DateTime? startDate; // When the lesson starts recurring from

  @HiveField(10)
  String? templateId; // For linking to a template

  @HiveField(11)
  String? notes;

  @HiveField(12)
  int weekNumber; // 1 or 2 for bi-weekly timetables, 0 for every week

  Lesson({
    required this.id,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.recurrenceType = RecurrenceType.everyWeek,
    this.customIntervalWeeks,
    this.startDate,
    this.templateId,
    this.notes,
    this.weekNumber = 0,
  });

  /// Get start time as DateTime (uses a reference date)
  DateTime get startTime {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, startHour, startMinute);
  }

  /// Get end time as DateTime (uses a reference date)
  DateTime get endTime {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, endHour, endMinute);
  }

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

  /// Get day name
  String get dayName {
    const days = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dayOfWeek];
  }

  /// Check if this lesson overlaps with another lesson
  bool overlaps(Lesson other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    if (weekNumber != 0 &&
        other.weekNumber != 0 &&
        weekNumber != other.weekNumber) {
      return false;
    }

    final thisStart = startHour * 60 + startMinute;
    final thisEnd = endHour * 60 + endMinute;
    final otherStart = other.startHour * 60 + other.startMinute;
    final otherEnd = other.endHour * 60 + other.endMinute;

    return thisStart < otherEnd && thisEnd > otherStart;
  }

  /// Check if this lesson occurs on a given date
  bool occursOn(
    DateTime date, {
    bool invertWeekParity = false,
    DateTime? globalBase,
  }) {
    if (date.weekday != dayOfWeek) return false;

    if (startDate != null && date.isBefore(startDate!)) return false;

    switch (recurrenceType) {
      case RecurrenceType.everyWeek:
        return true;
      case RecurrenceType.everyTwoWeeks:
        // Determine base for parity: lesson.startDate takes precedence, otherwise use provided globalBase
        final base = startDate ?? globalBase;
        if (base == null) {
          final parity = getWeekNumber(date) % 2;
          final lessonParity = weekNumber % 2;
          final matches = weekNumber == 0 || parity == lessonParity;
          return invertWeekParity ? !matches : matches;
        }
        final weeksSince = date.difference(base).inDays ~/ 7;
        final occurs = weeksSince % 2 == 0;
        return invertWeekParity ? !occurs : occurs;
      case RecurrenceType.custom:
        final base = startDate ?? globalBase;
        if (base == null || customIntervalWeeks == null) return true;
        final weeksSinceCustom = date.difference(base).inDays ~/ 7;
        final occursCustom = weeksSinceCustom % customIntervalWeeks! == 0;
        return invertWeekParity ? !occursCustom : occursCustom;
    }
  }

  /// Get ISO week number
  static int getWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  Lesson copyWith({
    String? id,
    int? subjectId,
    int? dayOfWeek,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    RecurrenceType? recurrenceType,
    int? customIntervalWeeks,
    DateTime? startDate,
    String? templateId,
    String? notes,
    int? weekNumber,
  }) {
    return Lesson(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      customIntervalWeeks: customIntervalWeeks ?? this.customIntervalWeeks,
      startDate: startDate ?? this.startDate,
      templateId: templateId ?? this.templateId,
      notes: notes ?? this.notes,
      weekNumber: weekNumber ?? this.weekNumber,
    );
  }

  @override
  String toString() {
    return 'Lesson(id: $id, subjectId: $subjectId, day: $dayName, $formattedStartTime-$formattedEndTime)';
  }
}

@HiveType(typeId: 3)
enum RecurrenceType {
  @HiveField(0)
  everyWeek,

  @HiveField(1)
  everyTwoWeeks,

  @HiveField(2)
  custom,
}
