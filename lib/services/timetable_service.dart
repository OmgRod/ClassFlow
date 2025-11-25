import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
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

  /// Get lessons for a specific date
  List<Lesson> getLessonsForDate(DateTime date) {
    return _lessons.where((l) => l.occursOn(date)).toList()
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
