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
    _subjects = DatabaseService.subjectsBox.values.toList();
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
    await DatabaseService.subjectsBox.put(subject.id, subject);
    _loadSubjects();
    return subject;
  }

  /// Update an existing subject
  Future<void> updateSubject(Subject subject) async {
    subject.name = Subject.formatName(subject.name);
    await DatabaseService.subjectsBox.put(subject.id, subject);
    _loadSubjects();
  }

  /// Delete a subject
  Future<void> deleteSubject(int id) async {
    await DatabaseService.subjectsBox.delete(id);
    
    // Also delete associated books
    final booksToDelete = DatabaseService.booksBox.values
        .where((book) => book.subjectId == id)
        .toList();
    for (final book in booksToDelete) {
      await DatabaseService.booksBox.delete(book.id);
    }
    
    // Also delete associated lessons
    final lessonsToDelete = DatabaseService.lessonsBox.values
        .where((lesson) => lesson.subjectId == id)
        .toList();
    for (final lesson in lessonsToDelete) {
      await DatabaseService.lessonsBox.delete(lesson.id);
    }
    
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
