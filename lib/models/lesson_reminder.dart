class LessonReminder {
  String id;
  String lessonId;
  int minutesBefore;
  bool enabled;
  DateTime? lastNotified;

  LessonReminder({
    required this.id,
    required this.lessonId,
    this.minutesBefore = 15,
    this.enabled = true,
    this.lastNotified,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'minutesBefore': minutesBefore,
      'enabled': enabled,
      'lastNotified': lastNotified?.toIso8601String(),
    };
  }

  factory LessonReminder.fromJson(Map<String, dynamic> json) {
    return LessonReminder(
      id: json['id'] as String,
      lessonId: json['lessonId'] as String,
      minutesBefore: json['minutesBefore'] as int? ?? 15,
      enabled: json['enabled'] as bool? ?? true,
      lastNotified: json['lastNotified'] != null
          ? DateTime.parse(json['lastNotified'] as String)
          : null,
    );
  }

  LessonReminder copyWith({
    String? id,
    String? lessonId,
    int? minutesBefore,
    bool? enabled,
    DateTime? lastNotified,
  }) {
    return LessonReminder(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      minutesBefore: minutesBefore ?? this.minutesBefore,
      enabled: enabled ?? this.enabled,
      lastNotified: lastNotified ?? this.lastNotified,
    );
  }

  @override
  String toString() {
    return 'LessonReminder(id: $id, lessonId: $lessonId, minutesBefore: $minutesBefore, enabled: $enabled)';
  }
}

class ReminderPreset {
  final String label;
  final int minutes;

  const ReminderPreset(this.label, this.minutes);

  static const List<ReminderPreset> presets = [
    ReminderPreset('5 minutes before', 5),
    ReminderPreset('10 minutes before', 10),
    ReminderPreset('15 minutes before', 15),
    ReminderPreset('30 minutes before', 30),
    ReminderPreset('1 hour before', 60),
  ];
}
