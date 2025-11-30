import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/lesson_reminder.dart';
import 'database_service.dart';

class ReminderService extends ChangeNotifier {
  List<LessonReminder> _reminders = [];
  bool _notificationsEnabled = true;

  ReminderService() {
    _loadReminders();
  }

  List<LessonReminder> get reminders => List.unmodifiable(_reminders);
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> _loadReminders() async {
    final data = DatabaseService.settings['reminders'] as List?;
    if (data != null) {
      _reminders = data
          .map((item) => LessonReminder.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    _notificationsEnabled =
        DatabaseService.settings['notificationsEnabled'] as bool? ?? true;

    notifyListeners();
  }

  Future<void> _saveReminders() async {
    DatabaseService.settings['reminders'] = _reminders
        .map((r) => r.toJson())
        .toList();
    await DatabaseService.save();
    notifyListeners();
  }

  Future<LessonReminder> createReminder(
    String lessonId, {
    int minutesBefore = 15,
  }) async {
    final reminder = LessonReminder(
      id: const Uuid().v4(),
      lessonId: lessonId,
      minutesBefore: minutesBefore,
    );

    _reminders.add(reminder);
    await _saveReminders();
    return reminder;
  }

  Future<void> updateReminder(LessonReminder reminder) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = reminder;
      await _saveReminders();
    }
  }

  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    await _saveReminders();
  }

  List<LessonReminder> getRemindersForLesson(String lessonId) {
    return _reminders.where((r) => r.lessonId == lessonId).toList();
  }

  Future<void> toggleReminder(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(
        enabled: !_reminders[index].enabled,
      );
      await _saveReminders();
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    DatabaseService.settings['notificationsEnabled'] = enabled;
    await DatabaseService.save();
    notifyListeners();
  }

  List<LessonReminder> get enabledReminders {
    return _reminders.where((r) => r.enabled).toList();
  }

  bool hasReminders(String lessonId) {
    return _reminders.any((r) => r.lessonId == lessonId);
  }

  DateTime? getNextReminderTime(String lessonId, DateTime lessonTime) {
    final lessonReminders = getRemindersForLesson(
      lessonId,
    ).where((r) => r.enabled).toList();

    if (lessonReminders.isEmpty || !_notificationsEnabled) {
      return null;
    }

    final minMinutes = lessonReminders
        .map((r) => r.minutesBefore)
        .reduce((a, b) => a < b ? a : b);

    return lessonTime.subtract(Duration(minutes: minMinutes));
  }

  Future<void> deleteRemindersForLesson(String lessonId) async {
    _reminders.removeWhere((r) => r.lessonId == lessonId);
    await _saveReminders();
  }

  Future<void> markNotified(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(
        lastNotified: DateTime.now(),
      );
      await _saveReminders();
    }
  }

  Future<void> clearAllReminders() async {
    _reminders.clear();
    await _saveReminders();
  }
}
