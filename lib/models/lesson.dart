class Lesson {
  String id; // UUID
  int subjectId;
  int dayOfWeek; // 1 = Monday, 7 = Sunday
  int startHour;
  int startMinute;
  int endHour;
  int endMinute;
  RecurrenceType recurrenceType;
  int? customIntervalWeeks; // For custom recurrence
  DateTime? startDate; // When the lesson starts recurring from
  String? templateId; // For linking to a template
  String? notes;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'dayOfWeek': dayOfWeek,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'recurrenceType': recurrenceType.toJson(),
      'customIntervalWeeks': customIntervalWeeks,
      'startDate': startDate?.toIso8601String(),
      'templateId': templateId,
      'notes': notes,
      'weekNumber': weekNumber,
    };
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      subjectId: json['subjectId'] as int,
      dayOfWeek: json['dayOfWeek'] as int,
      startHour: json['startHour'] as int,
      startMinute: json['startMinute'] as int,
      endHour: json['endHour'] as int,
      endMinute: json['endMinute'] as int,
      recurrenceType: RecurrenceTypeJson.fromJson(
        json['recurrenceType'] as String,
      ),
      customIntervalWeeks: json['customIntervalWeeks'] as int?,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      templateId: json['templateId'] as String?,
      notes: json['notes'] as String?,
      weekNumber: json['weekNumber'] as int? ?? 0,
    );
  }
}

enum RecurrenceType { everyWeek, everyTwoWeeks, custom }

extension RecurrenceTypeJson on RecurrenceType {
  String toJson() {
    switch (this) {
      case RecurrenceType.everyWeek:
        return 'everyWeek';
      case RecurrenceType.everyTwoWeeks:
        return 'everyTwoWeeks';
      case RecurrenceType.custom:
        return 'custom';
    }
  }

  static RecurrenceType fromJson(String value) {
    switch (value) {
      case 'everyTwoWeeks':
        return RecurrenceType.everyTwoWeeks;
      case 'custom':
        return RecurrenceType.custom;
      case 'everyWeek':
      default:
        return RecurrenceType.everyWeek;
    }
  }
}
