import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'database_service.dart';

/// Service for archiving and restoring items instead of permanent deletion
class ArchiveService extends ChangeNotifier {
  List<ArchivedItem> _archivedItems = [];

  ArchiveService() {
    _loadArchivedItems();
  }

  List<ArchivedItem> get archivedItems => List.unmodifiable(_archivedItems);

  List<ArchivedItem> getArchivedByType(String type) {
    return _archivedItems.where((item) => item.type == type).toList();
  }

  Future<void> _loadArchivedItems() async {
    final data = DatabaseService.settings['archivedItems'] as List?;
    if (data != null) {
      _archivedItems = data
          .map((item) => ArchivedItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _saveArchivedItems() async {
    DatabaseService.settings['archivedItems'] = _archivedItems
        .map((item) => item.toJson())
        .toList();
    await DatabaseService.save();
    notifyListeners();
  }

  /// Archive a subject
  Future<void> archiveSubject(Subject subject, {String? reason}) async {
    final archivedItem = ArchivedItem(
      id: subject.id.toString(),
      type: 'subject',
      data: subject.toJson(),
      reason: reason,
    );

    _archivedItems.add(archivedItem);
    await _saveArchivedItems();
  }

  /// Archive a book
  Future<void> archiveBook(Book book, {String? reason}) async {
    final archivedItem = ArchivedItem(
      id: book.id.toString(),
      type: 'book',
      data: book.toJson(),
      reason: reason,
    );

    _archivedItems.add(archivedItem);
    await _saveArchivedItems();
  }

  /// Archive a lesson
  Future<void> archiveLesson(Lesson lesson, {String? reason}) async {
    final archivedItem = ArchivedItem(
      id: lesson.id,
      type: 'lesson',
      data: lesson.toJson(),
      reason: reason,
    );

    _archivedItems.add(archivedItem);
    await _saveArchivedItems();
  }

  /// Restore an archived subject
  Subject? restoreSubject(String id) {
    final index = _archivedItems.indexWhere(
      (item) => item.id == id && item.type == 'subject',
    );

    if (index == -1) return null;

    final archivedItem = _archivedItems.removeAt(index);
    _saveArchivedItems();

    return Subject.fromJson(archivedItem.data);
  }

  /// Restore an archived book
  Book? restoreBook(String id) {
    final index = _archivedItems.indexWhere(
      (item) => item.id == id && item.type == 'book',
    );

    if (index == -1) return null;

    final archivedItem = _archivedItems.removeAt(index);
    _saveArchivedItems();

    return Book.fromJson(archivedItem.data);
  }

  /// Restore an archived lesson
  Lesson? restoreLesson(String id) {
    final index = _archivedItems.indexWhere(
      (item) => item.id == id && item.type == 'lesson',
    );

    if (index == -1) return null;

    final archivedItem = _archivedItems.removeAt(index);
    _saveArchivedItems();

    return Lesson.fromJson(archivedItem.data);
  }

  /// Permanently delete an archived item
  Future<void> permanentlyDelete(String id) async {
    _archivedItems.removeWhere((item) => item.id == id);
    await _saveArchivedItems();
  }

  /// Clear all archived items (use with caution)
  Future<void> clearArchive() async {
    _archivedItems.clear();
    await _saveArchivedItems();
  }

  /// Get count of archived items by type
  int getArchivedCount(String type) {
    return _archivedItems.where((item) => item.type == type).length;
  }

  /// Get all archived items sorted by date (newest first)
  List<ArchivedItem> get sortedByDate {
    final sorted = List<ArchivedItem>.from(_archivedItems);
    sorted.sort((a, b) => b.archivedAt.compareTo(a.archivedAt));
    return sorted;
  }

  /// Get archived items older than specified days
  List<ArchivedItem> getOlderThan(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _archivedItems
        .where((item) => item.archivedAt.isBefore(cutoffDate))
        .toList();
  }
}
