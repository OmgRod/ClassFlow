import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
// Hive import not needed here; use DatabaseService.specialLessonsBox
import '../models/models.dart';
import 'database_service.dart';

class TimetableService extends ChangeNotifier {
  List<Lesson> _lessons = [];
  List<LessonTemplate> _templates = [];
  final Uuid _uuid = const Uuid();

  List<Lesson> get lessons => _lessons;
  List<LessonTemplate> get templates => _templates;

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
    _lessons = DatabaseService.lessonsBox.values.toList();
    _templates = DatabaseService.templatesBox.values.toList();
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
    await DatabaseService.lessonsBox.put(lesson.id, lesson);
    _loadData();
    return lesson;
  }

  /// Update an existing lesson
  Future<void> updateLesson(Lesson lesson) async {
    await DatabaseService.lessonsBox.put(lesson.id, lesson);
    _loadData();
  }

  /// Delete a lesson
  Future<void> deleteLesson(String id) async {
    await DatabaseService.lessonsBox.delete(id);
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
      if (weekNumber != null && l.weekNumber != 0 && l.weekNumber != weekNumber) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final aMinutes = a.startHour * 60 + a.startMinute;
        final bMinutes = b.startHour * 60 + b.startMinute;
        return aMinutes.compareTo(bMinutes);
      });
  }

  /// Get lessons for a specific calendar date (respects recurrence rules)
  List<Lesson> getLessonsForCalendarDate(DateTime date, {int? weekNumber}) {
    // Read global invert setting and global week1 base from settings box if available
    bool invert = false;
    DateTime? globalBase;
    try {
      invert = DatabaseService.settingsBox.get('invertWeekParity', defaultValue: false) as bool;
      final iso = DatabaseService.settingsBox.get('week1StartDate') as String?;
      if (iso != null) globalBase = DateTime.tryParse(iso);
    } catch (_) {}

    // collect special lessons for the date (they override regular lessons)
    final specialForDate = DatabaseService.specialLessonsBox.values
      .whereType<SpecialLesson>()
      .where((s) => isSameDate(s.date, date))
      .toList();

    return _lessons.where((l) {
      // must match weekday
      if (l.dayOfWeek != date.weekday) return false;

      // respect explicit weekNumber filter (1 or 2). If lesson has a specific weekNumber, enforce it.
      if (weekNumber != null && l.weekNumber != 0 && l.weekNumber != weekNumber) {
        return false;
      }

      // respect recurrence rules (occursOn handles everyWeek, everyTwoWeeks, custom)
      if (!l.occursOn(date, invertWeekParity: invert, globalBase: globalBase)) return false;

      // if a special lesson explicitly overrides this lesson, exclude it
      if (specialForDate.any((s) => s.originalLessonId != null && s.originalLessonId == l.id)) {
        return false;
      }

      // if a special lesson overlaps and targets same subject, treat it as overridden
      if (specialForDate.any((s) => s.subjectId == l.subjectId && lessonsOverlapSpecial(l, s))) {
        return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        final aMinutes = a.startHour * 60 + a.startMinute;
        final bMinutes = b.startHour * 60 + b.startMinute;
        return aMinutes.compareTo(bMinutes);
      });
  }

  /// Get lessons for a specific date
  List<Lesson> getLessonsForDate(DateTime date) {
    // Use global settings for invert and globalBase if available
    bool invert = false;
    DateTime? globalBase;
    try {
      invert = DatabaseService.settingsBox.get('invertWeekParity', defaultValue: false) as bool;
      final iso = DatabaseService.settingsBox.get('week1StartDate') as String?;
      if (iso != null) globalBase = DateTime.tryParse(iso);
    } catch (_) {}

    return _lessons.where((l) => l.occursOn(date, invertWeekParity: invert, globalBase: globalBase)).toList()
      ..sort((a, b) {
        final aMinutes = a.startHour * 60 + a.startMinute;
        final bMinutes = b.startHour * 60 + b.startMinute;
        return aMinutes.compareTo(bMinutes);
      });
  }

  /// Get special lessons for a specific date
  List<SpecialLesson> getSpecialLessonsForDate(DateTime date) {
    try {
      final box = DatabaseService.specialLessonsBox;
      return box.values.whereType<SpecialLesson>().where((s) => isSameDate(s.date, date)).toList()
        ..sort((a, b) {
          final aMinutes = a.startHour * 60 + a.startMinute;
          final bMinutes = b.startHour * 60 + b.startMinute;
          return aMinutes.compareTo(bMinutes);
        });
    } catch (_) {
      return [];
    }
  }

  /// Add a special lesson for a specific date
  Future<SpecialLesson> addSpecialLesson({
    required String id,
    required DateTime date,
    required int subjectId,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    String? originalLessonId,
    String? notes,
  }) async {
    final box = DatabaseService.specialLessonsBox;
    final special = SpecialLesson(
      id: id,
      date: date,
      subjectId: subjectId,
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
      originalLessonId: originalLessonId,
      notes: notes,
    );
    await box.put(special.id, special);
    _loadData();
    return special;
  }

  Future<void> deleteSpecialLesson(String id) async {
    final box = DatabaseService.specialLessonsBox;
    await box.delete(id);
    _loadData();
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
    final lessonsToC = _lessons.where((l) => l.weekNumber == fromWeekNumber).toList();
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

  // ============== TEMPLATE METHODS ==============

  /// Add a new template
  Future<LessonTemplate> addTemplate({
    required String name,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    String? description,
  }) async {
    final template = LessonTemplate(
      id: _uuid.v4(),
      name: name,
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
      description: description,
    );
    await DatabaseService.templatesBox.put(template.id, template);
    _loadData();
    return template;
  }

  /// Update an existing template
  Future<void> updateTemplate(LessonTemplate template) async {
    await DatabaseService.templatesBox.put(template.id, template);
    _loadData();
  }

  /// Delete a template
  Future<void> deleteTemplate(String id) async {
    await DatabaseService.templatesBox.delete(id);
    _loadData();
  }

  /// Get template by ID
  LessonTemplate? getTemplateById(String id) {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Create a lesson from a template
  Future<Lesson> createLessonFromTemplate({
    required LessonTemplate template,
    required int subjectId,
    required int dayOfWeek,
    RecurrenceType recurrenceType = RecurrenceType.everyWeek,
    int weekNumber = 0,
  }) async {
    return addLesson(
      subjectId: subjectId,
      dayOfWeek: dayOfWeek,
      startHour: template.startHour,
      startMinute: template.startMinute,
      endHour: template.endHour,
      endMinute: template.endMinute,
      recurrenceType: recurrenceType,
      templateId: template.id,
      weekNumber: weekNumber,
    );
  }

  /// Refresh data from database
  void refresh() {
    _loadData();
  }
}
