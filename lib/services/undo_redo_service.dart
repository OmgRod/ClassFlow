import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'database_service.dart';

/// Service for managing undo/redo operations
class UndoRedoService extends ChangeNotifier {
  final List<UndoAction> _undoStack = [];
  final List<UndoAction> _redoStack = [];
  final int maxStackSize = 50;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  /// Record an action that can be undone
  void recordAction(UndoAction action) {
    _undoStack.add(action);
    _redoStack.clear(); // Clear redo stack when new action is performed

    // Limit stack size
    if (_undoStack.length > maxStackSize) {
      _undoStack.removeAt(0);
    }

    notifyListeners();
  }

  /// Undo the last action
  Future<void> undo() async {
    if (!canUndo) return;

    final action = _undoStack.removeLast();
    await action.undo();
    _redoStack.add(action);

    notifyListeners();
  }

  /// Redo the last undone action
  Future<void> redo() async {
    if (!canRedo) return;

    final action = _redoStack.removeLast();
    await action.redo();
    _undoStack.add(action);

    notifyListeners();
  }

  /// Get description of last undoable action
  String? getLastUndoDescription() {
    return canUndo ? _undoStack.last.description : null;
  }

  /// Get description of last redoable action
  String? getLastRedoDescription() {
    return canRedo ? _redoStack.last.description : null;
  }

  /// Clear all undo/redo history
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  /// Clear only redo stack
  void clearRedo() {
    _redoStack.clear();
    notifyListeners();
  }
}

/// Base class for undoable actions
abstract class UndoAction {
  final String description;
  final DateTime timestamp;

  UndoAction(this.description) : timestamp = DateTime.now();

  Future<void> undo();
  Future<void> redo();
}

/// Delete subject action
class DeleteSubjectAction extends UndoAction {
  final Subject subject;
  final List<Subject> subjectsList;

  DeleteSubjectAction(this.subject, this.subjectsList)
    : super('Delete subject "${subject.name}"');

  @override
  Future<void> undo() async {
    subjectsList.add(subject);
    DatabaseService.subjects.clear();
    DatabaseService.subjects.addAll(subjectsList);
    await DatabaseService.save();
  }

  @override
  Future<void> redo() async {
    subjectsList.removeWhere((s) => s.id == subject.id);
    DatabaseService.subjects.clear();
    DatabaseService.subjects.addAll(subjectsList);
    await DatabaseService.save();
  }
}

/// Delete book action
class DeleteBookAction extends UndoAction {
  final Book book;
  final List<Book> booksList;

  DeleteBookAction(this.book, this.booksList)
    : super('Delete book ID ${book.id}');

  @override
  Future<void> undo() async {
    booksList.add(book);
    DatabaseService.books.clear();
    DatabaseService.books.addAll(booksList);
    await DatabaseService.save();
  }

  @override
  Future<void> redo() async {
    booksList.removeWhere((b) => b.id == book.id);
    DatabaseService.books.clear();
    DatabaseService.books.addAll(booksList);
    await DatabaseService.save();
  }
}

/// Delete lesson action
class DeleteLessonAction extends UndoAction {
  final Lesson lesson;
  final List<Lesson> lessonsList;

  DeleteLessonAction(this.lesson, this.lessonsList) : super('Delete lesson');

  @override
  Future<void> undo() async {
    lessonsList.add(lesson);
    DatabaseService.lessons.clear();
    DatabaseService.lessons.addAll(lessonsList);
    await DatabaseService.save();
  }

  @override
  Future<void> redo() async {
    lessonsList.removeWhere((l) => l.id == lesson.id);
    DatabaseService.lessons.clear();
    DatabaseService.lessons.addAll(lessonsList);
    await DatabaseService.save();
  }
}

/// Update subject action
class UpdateSubjectAction extends UndoAction {
  final Subject oldSubject;
  final Subject newSubject;
  final List<Subject> subjectsList;

  UpdateSubjectAction(this.oldSubject, this.newSubject, this.subjectsList)
    : super('Update subject "${newSubject.name}"');

  @override
  Future<void> undo() async {
    final index = subjectsList.indexWhere((s) => s.id == newSubject.id);
    if (index != -1) {
      subjectsList[index] = oldSubject;
      DatabaseService.subjects.clear();
      DatabaseService.subjects.addAll(subjectsList);
      await DatabaseService.save();
    }
  }

  @override
  Future<void> redo() async {
    final index = subjectsList.indexWhere((s) => s.id == oldSubject.id);
    if (index != -1) {
      subjectsList[index] = newSubject;
      DatabaseService.subjects.clear();
      DatabaseService.subjects.addAll(subjectsList);
      await DatabaseService.save();
    }
  }
}

/// Update book action
class UpdateBookAction extends UndoAction {
  final Book oldBook;
  final Book newBook;
  final List<Book> booksList;

  UpdateBookAction(this.oldBook, this.newBook, this.booksList)
    : super('Update book ID ${newBook.id}');

  @override
  Future<void> undo() async {
    final index = booksList.indexWhere((b) => b.id == newBook.id);
    if (index != -1) {
      booksList[index] = oldBook;
      DatabaseService.books.clear();
      DatabaseService.books.addAll(booksList);
      await DatabaseService.save();
    }
  }

  @override
  Future<void> redo() async {
    final index = booksList.indexWhere((b) => b.id == oldBook.id);
    if (index != -1) {
      booksList[index] = newBook;
      DatabaseService.books.clear();
      DatabaseService.books.addAll(booksList);
      await DatabaseService.save();
    }
  }
}

/// Update lesson action
class UpdateLessonAction extends UndoAction {
  final Lesson oldLesson;
  final Lesson newLesson;
  final List<Lesson> lessonsList;

  UpdateLessonAction(this.oldLesson, this.newLesson, this.lessonsList)
    : super('Update lesson');

  @override
  Future<void> undo() async {
    final index = lessonsList.indexWhere((l) => l.id == newLesson.id);
    if (index != -1) {
      lessonsList[index] = oldLesson;
      DatabaseService.lessons.clear();
      DatabaseService.lessons.addAll(lessonsList);
      await DatabaseService.save();
    }
  }

  @override
  Future<void> redo() async {
    final index = lessonsList.indexWhere((l) => l.id == oldLesson.id);
    if (index != -1) {
      lessonsList[index] = newLesson;
      DatabaseService.lessons.clear();
      DatabaseService.lessons.addAll(lessonsList);
      await DatabaseService.save();
    }
  }
}

/// Batch delete action
class BatchDeleteAction extends UndoAction {
  final List<dynamic> items;
  final List<dynamic> originalList;
  final String itemType;

  BatchDeleteAction(this.items, this.originalList, this.itemType)
    : super('Delete ${items.length} $itemType${items.length == 1 ? "" : "s"}');

  @override
  Future<void> undo() async {
    originalList.addAll(items);
    await _saveByType();
  }

  @override
  Future<void> redo() async {
    for (final item in items) {
      if (item is Subject) {
        originalList.removeWhere((s) => s.id == item.id);
      } else if (item is Book) {
        originalList.removeWhere((b) => b.id == item.id);
      } else if (item is Lesson) {
        originalList.removeWhere((l) => l.id == item.id);
      }
    }
    await _saveByType();
  }

  Future<void> _saveByType() async {
    if (items.first is Subject) {
      DatabaseService.subjects.clear();
      DatabaseService.subjects.addAll(originalList as List<Subject>);
    } else if (items.first is Book) {
      DatabaseService.books.clear();
      DatabaseService.books.addAll(originalList as List<Book>);
    } else if (items.first is Lesson) {
      DatabaseService.lessons.clear();
      DatabaseService.lessons.addAll(originalList as List<Lesson>);
    }
    await DatabaseService.save();
  }
}
