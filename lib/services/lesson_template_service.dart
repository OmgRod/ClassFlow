import 'package:flutter/foundation.dart';
import '../models/lesson_template.dart';
import '../models/lesson.dart';
import 'database_service.dart';
import 'package:uuid/uuid.dart';

class LessonTemplateService extends ChangeNotifier {
  List<LessonTemplate> _templates = [];

  List<LessonTemplate> get templates => _templates;

  LessonTemplateService() {
    _loadTemplates();
  }

  void _loadTemplates() {
    final data = DatabaseService.settings['lessonTemplates'] as List?;
    if (data != null) {
      _templates = data
          .map((t) => LessonTemplate.fromJson(t as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _saveTemplates() async {
    DatabaseService.settings['lessonTemplates'] = _templates
        .map((t) => t.toJson())
        .toList();
    await DatabaseService.save();
    notifyListeners();
  }

  /// Create a template from current lessons
  Future<LessonTemplate> createTemplateFromLessons({
    required String name,
    String? description,
    required List<Lesson> lessons,
  }) async {
    final template = LessonTemplate(
      id: const Uuid().v4(),
      name: name,
      description: description,
      lessons: lessons
          .map(
            (l) => TemplateLessonEntry(
              subjectId: l.subjectId,
              dayOfWeek: l.dayOfWeek,
              startHour: l.startHour,
              startMinute: l.startMinute,
              endHour: l.endHour,
              endMinute: l.endMinute,
              notes: l.notes,
              weekNumber: l.weekNumber,
            ),
          )
          .toList(),
    );

    _templates.add(template);
    await _saveTemplates();
    return template;
  }

  /// Create a new empty template
  Future<LessonTemplate> createTemplate({
    required String name,
    String? description,
  }) async {
    final template = LessonTemplate(
      id: const Uuid().v4(),
      name: name,
      description: description,
      lessons: [],
    );

    _templates.add(template);
    await _saveTemplates();
    return template;
  }

  /// Update a template
  Future<void> updateTemplate(LessonTemplate template) async {
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _templates[index] = template;
      await _saveTemplates();
    }
  }

  /// Delete a template
  Future<void> deleteTemplate(String id) async {
    _templates.removeWhere((t) => t.id == id);
    await _saveTemplates();
  }

  /// Get template by ID
  LessonTemplate? getTemplateById(String id) {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Apply a template - creates lessons from the template
  Future<List<Lesson>> applyTemplate(String templateId) async {
    final template = getTemplateById(templateId);
    if (template == null) return [];

    final lessons = template.lessons.map((entry) {
      return Lesson(
        id: const Uuid().v4(),
        subjectId: entry.subjectId,
        dayOfWeek: entry.dayOfWeek,
        startHour: entry.startHour,
        startMinute: entry.startMinute,
        endHour: entry.endHour,
        endMinute: entry.endMinute,
        notes: entry.notes,
        weekNumber: entry.weekNumber,
        templateId: templateId,
      );
    }).toList();

    // Update last used time
    template.lastUsedAt = DateTime.now();
    await updateTemplate(template);

    return lessons;
  }

  /// Get templates sorted by last used (most recent first)
  List<LessonTemplate> get templatesByLastUsed {
    final sorted = List<LessonTemplate>.from(_templates);
    sorted.sort((a, b) {
      if (a.lastUsedAt == null && b.lastUsedAt == null) {
        return b.createdAt.compareTo(a.createdAt);
      }
      if (a.lastUsedAt == null) return 1;
      if (b.lastUsedAt == null) return -1;
      return b.lastUsedAt!.compareTo(a.lastUsedAt!);
    });
    return sorted;
  }

  /// Get templates sorted by name
  List<LessonTemplate> get templatesByName {
    final sorted = List<LessonTemplate>.from(_templates);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }
}
