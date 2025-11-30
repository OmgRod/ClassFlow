import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'database_service.dart';

class SubjectService extends ChangeNotifier {
  List<Subject> _subjects = [];

  List<Subject> get subjects => _subjects;

  SubjectService() {
    _loadSubjects();
  }

  void _loadSubjects() {
    _subjects = List<Subject>.from(DatabaseService.subjects);
    notifyListeners();
  }

  /// Get next available ID
  int get nextId {
    if (_subjects.isEmpty) return 1;
    return _subjects.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Add a new subject
  Future<Subject> addSubject({
    required String name,
    List<int>? bookIds,
    int? colorValue,
  }) async {
    final formattedName = Subject.formatName(name);
    final subject = Subject(
      id: nextId,
      name: formattedName,
      bookIds: bookIds,
      colorValue: colorValue,
    );
    DatabaseService.subjects.add(subject);
    await DatabaseService.save();
    _loadSubjects();
    return subject;
  }

  /// Update an existing subject
  Future<void> updateSubject(Subject subject) async {
    subject.name = Subject.formatName(subject.name);
    final index = DatabaseService.subjects.indexWhere(
      (s) => s.id == subject.id,
    );
    if (index != -1) {
      DatabaseService.subjects[index] = subject;
      await DatabaseService.save();
    }
    _loadSubjects();
  }

  /// Delete a subject
  Future<void> deleteSubject(int id) async {
    DatabaseService.subjects.removeWhere((s) => s.id == id);

    // Also delete associated books
    DatabaseService.books.removeWhere((book) => book.subjectId == id);

    // Also delete associated lessons
    DatabaseService.lessons.removeWhere((lesson) => lesson.subjectId == id);

    await DatabaseService.save();
    _loadSubjects();
  }

  /// Get subject by ID
  Subject? getSubjectById(int id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Reorder subjects
  Future<void> reorderSubjects(List<Subject> newOrder) async {
    DatabaseService.subjects.clear();
    DatabaseService.subjects.addAll(newOrder);
    await DatabaseService.save();
    _loadSubjects();
  }

  /// Add book ID to subject
  Future<void> addBookToSubject(int subjectId, int bookId) async {
    final subject = getSubjectById(subjectId);
    if (subject != null && !subject.bookIds.contains(bookId)) {
      subject.bookIds.add(bookId);
      await updateSubject(subject);
    }
  }

  /// Remove book ID from subject
  Future<void> removeBookFromSubject(int subjectId, int bookId) async {
    final subject = getSubjectById(subjectId);
    if (subject != null) {
      subject.bookIds.remove(bookId);
      await updateSubject(subject);
    }
  }

  /// Refresh subjects from database
  void refresh() {
    _loadSubjects();
  }
}
