import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'database_service.dart';

class TimetableService extends ChangeNotifier {
  List<Lesson> _lessons = [];
  final Uuid _uuid = const Uuid();

  List<Lesson> get lessons => _lessons;

  TimetableService() {
    _loadData();
  }

  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool lessonsOverlapSpecial(Lesson l, SpecialLesson s) {
    if (l.dayOfWeek != s.date.weekday) return false;
    final lStart = l.startHour * 60 + l.startMinute;
    final lEnd = l.endHour * 60 + l.endMinute;
    final sStart = s.startHour * 60 + s.startMinute;
    final sEnd = s.endHour * 60 + s.endMinute;
    return lStart < sEnd && lEnd > sStart;
  }

  void _loadData() {
    _lessons = List<Lesson>.from(DatabaseService.lessons);
    notifyListeners();
  }

  // ============== LESSON METHODS ==============

  /// Add a new lesson
  Future<Lesson> addLesson({
    required int subjectId,
    required int dayOfWeek,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    RecurrenceType recurrenceType = RecurrenceType.everyWeek,
    int? customIntervalWeeks,
    DateTime? startDate,
    String? templateId,
    String? notes,
    int weekNumber = 0,
  }) async {
    final lesson = Lesson(
      id: _uuid.v4(),
      subjectId: subjectId,
      dayOfWeek: dayOfWeek,
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
      recurrenceType: recurrenceType,
      customIntervalWeeks: customIntervalWeeks,
      startDate: startDate,
      templateId: templateId,
      notes: notes,
      weekNumber: weekNumber,
    );
    DatabaseService.lessons.removeWhere((l) => l.id == lesson.id);
    DatabaseService.lessons.add(lesson);
    await DatabaseService.save();
    _loadData();
    return lesson;
  }

  /// Update an existing lesson
  Future<void> updateLesson(Lesson lesson) async {
    final index = DatabaseService.lessons.indexWhere((l) => l.id == lesson.id);
    if (index != -1) {
      DatabaseService.lessons[index] = lesson;
    } else {
      DatabaseService.lessons.add(lesson);
    }
    await DatabaseService.save();
    _loadData();
  }

  /// Delete a lesson
  Future<void> deleteLesson(String id) async {
    DatabaseService.lessons.removeWhere((l) => l.id == id);
    await DatabaseService.save();
    _loadData();
  }

  /// Get lesson by ID
  Lesson? getLessonById(String id) {
    try {
      return _lessons.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get lessons for a specific day
  List<Lesson> getLessonsForDay(int dayOfWeek, {int? weekNumber}) {
    return _lessons.where((l) {
      if (l.dayOfWeek != dayOfWeek) return false;
      if (weekNumber != null &&
          l.weekNumber != 0 &&
          l.weekNumber != weekNumber) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) {
      final aMinutes = a.startHour * 60 + a.startMinute;
      final bMinutes = b.startHour * 60 + b.startMinute;
      return aMinutes.compareTo(bMinutes);
    });
  }

  /// Get lessons for a specific calendar date (respects recurrence rules)
  List<Lesson> getLessonsForCalendarDate(DateTime date, {int? weekNumber}) {
    // Read global invert setting and global week1 base from settings box if available
    bool invert =
        (DatabaseService.settings['invertWeekParity'] as bool?) ?? false;
    DateTime? globalBase;
    final iso = DatabaseService.settings['week1StartDate'] as String?;
    if (iso != null) {
      globalBase = DateTime.tryParse(iso);
    }

    return _lessons.where((l) {
      // must match weekday
      if (l.dayOfWeek != date.weekday) return false;

      // respect explicit weekNumber filter (1 or 2). If lesson has a specific weekNumber, enforce it.
      if (weekNumber != null &&
          l.weekNumber != 0 &&
          l.weekNumber != weekNumber) {
        return false;
      }

      // respect recurrence rules (occursOn handles everyWeek, everyTwoWeeks, custom)
      if (!l.occursOn(date, invertWeekParity: invert, globalBase: globalBase)) {
        return false;
      }

      return true;
    }).toList()..sort((a, b) {
      final aMinutes = a.startHour * 60 + a.startMinute;
      final bMinutes = b.startHour * 60 + b.startMinute;
      return aMinutes.compareTo(bMinutes);
    });
  }

  /// Get lessons for a specific date
  List<Lesson> getLessonsForDate(DateTime date) {
    bool invert =
        (DatabaseService.settings['invertWeekParity'] as bool?) ?? false;
    DateTime? globalBase;
    final iso = DatabaseService.settings['week1StartDate'] as String?;
    if (iso != null) {
      globalBase = DateTime.tryParse(iso);
    }

    return _lessons
        .where(
          (l) => l.occursOn(
            date,
            invertWeekParity: invert,
            globalBase: globalBase,
          ),
        )
        .toList()
      ..sort((a, b) {
        final aMinutes = a.startHour * 60 + a.startMinute;
        final bMinutes = b.startHour * 60 + b.startMinute;
        return aMinutes.compareTo(bMinutes);
      });
  }

  /// Get all lessons for a subject
  List<Lesson> getLessonsForSubject(int subjectId) {
    return _lessons.where((l) => l.subjectId == subjectId).toList();
  }

  /// Check for conflicting lessons
  List<Lesson> getConflicts(Lesson lesson) {
    return _lessons
        .where((l) => l.id != lesson.id && l.overlaps(lesson))
        .toList();
  }

  /// Check if adding a lesson would cause conflicts
  bool hasConflicts(Lesson lesson) {
    return getConflicts(lesson).isNotEmpty;
  }

  /// Copy lessons from one week to another
  Future<void> copyWeek({
    required int fromWeekNumber,
    required int toWeekNumber,
  }) async {
    final lessonsToC = _lessons
        .where((l) => l.weekNumber == fromWeekNumber)
        .toList();
    for (final lesson in lessonsToC) {
      await addLesson(
        subjectId: lesson.subjectId,
        dayOfWeek: lesson.dayOfWeek,
        startHour: lesson.startHour,
        startMinute: lesson.startMinute,
        endHour: lesson.endHour,
        endMinute: lesson.endMinute,
        recurrenceType: lesson.recurrenceType,
        customIntervalWeeks: lesson.customIntervalWeeks,
        startDate: lesson.startDate,
        templateId: lesson.templateId,
        notes: lesson.notes,
        weekNumber: toWeekNumber,
      );
    }
  }

  /// Refresh data from database
  void refresh() {
    _loadData();
  }
}
