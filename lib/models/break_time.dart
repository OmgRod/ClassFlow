class BreakTime {
  String id; // UUID
  String name; // e.g., "Lunch", "Recess", "Morning Break"
  int dayOfWeek; // 1 = Monday, 7 = Sunday
  int startHour;
  int startMinute;
  int endHour;
  int endMinute;
  int weekNumber; // 0 = every week, 1 = week 1, 2 = week 2

  BreakTime({
    required this.id,
    required this.name,
    required this.dayOfWeek,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
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

  BreakTime copyWith({
    String? id,
    String? name,
    int? dayOfWeek,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    int? weekNumber,
  }) {
    return BreakTime(
      id: id ?? this.id,
      name: name ?? this.name,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      weekNumber: weekNumber ?? this.weekNumber,
    );
  }

  @override
  String toString() {
    return 'BreakTime(id: $id, name: $name, day: $dayOfWeek, $formattedStartTime-$formattedEndTime)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dayOfWeek': dayOfWeek,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'weekNumber': weekNumber,
    };
  }

  factory BreakTime.fromJson(Map<String, dynamic> json) {
    return BreakTime(
      id: json['id'] as String,
      name: json['name'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      startHour: json['startHour'] as int,
      startMinute: json['startMinute'] as int,
      endHour: json['endHour'] as int,
      endMinute: json['endMinute'] as int,
      weekNumber: json['weekNumber'] as int? ?? 0,
    );
  }
}
