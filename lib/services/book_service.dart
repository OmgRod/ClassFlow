import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import '../models/models.dart';
import 'database_service.dart';

class BookService extends ChangeNotifier {
  List<Book> _books = [];

  List<Book> get books => _books;

  BookService() {
    _syncSubjectBookMappings();
    _loadBooks();
  }

  /// Ensure that each Subject.bookIds reflects current books in the books box.
  void _syncSubjectBookMappings() {
    try {
      final allBooks = DatabaseService.booksBox.values.toList();
      final subjects = DatabaseService.subjectsBox.values.toList();

      for (final subj in subjects) {
        final ids = allBooks.where((b) => b.subjectId == subj.id).map((b) => b.id).toList();
        // Only write if different to avoid extra writes
        if (!(ListEquality().equals(ids, subj.bookIds))) {
          subj.bookIds
            ..clear()
            ..addAll(ids);
          DatabaseService.subjectsBox.put(subj.id, subj);
        }
      }
    } catch (_) {}
  }

  void _loadBooks() {
    _books = DatabaseService.booksBox.values.toList();
    try {
      debugPrint('BookService: loaded ${_books.length} books from box; keys=${DatabaseService.booksBox.keys.toList()}');
    } catch (_) {}
    notifyListeners();
  }

  /// Get next available ID
  int get nextId {
    if (_books.isEmpty) return 1;
    return _books.map((b) => b.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Add a new book with a specific ID
  Future<Book> addBook({
    required int subjectId,
    int? bookId,
    String? description,
  }) async {
    final book = Book(
      id: bookId ?? nextId,
      subjectId: subjectId,
      description: description,
    );
    try {
      await DatabaseService.booksBox.put(book.id, book);
    } catch (e, st) {
      debugPrint('Failed to persist book ${book.id}: $e\n$st');
      rethrow;
    }
    // Ensure the subject knows about this book ID
    try {
      final subj = DatabaseService.subjectsBox.get(subjectId);
      if (subj != null && !subj.bookIds.contains(book.id)) {
        subj.bookIds.add(book.id);
        await DatabaseService.subjectsBox.put(subj.id, subj);
      }
    } catch (_) {}

    _loadBooks();
    return book;
  }

  /// Update an existing book
  Future<void> updateBook(Book book) async {
    // Get existing book to detect subject change
    final existing = DatabaseService.booksBox.get(book.id);
    try {
      await DatabaseService.booksBox.put(book.id, book);
    } catch (e, st) {
      debugPrint('Failed to update book ${book.id}: $e\n$st');
      rethrow;
    }

    if (existing != null && existing.subjectId != book.subjectId) {
      // Remove from old subject
      try {
        final oldSubj = DatabaseService.subjectsBox.get(existing.subjectId);
        if (oldSubj != null && oldSubj.bookIds.contains(book.id)) {
          oldSubj.bookIds.remove(book.id);
          await DatabaseService.subjectsBox.put(oldSubj.id, oldSubj);
        }
      } catch (_) {}
      // Add to new subject
      try {
        final newSubj = DatabaseService.subjectsBox.get(book.subjectId);
        if (newSubj != null && !newSubj.bookIds.contains(book.id)) {
          newSubj.bookIds.add(book.id);
          await DatabaseService.subjectsBox.put(newSubj.id, newSubj);
        }
      } catch (_) {}
    }

    _loadBooks();
  }

  /// Delete a book
  Future<void> deleteBook(int id) async {
    // Remove book and update subject mapping
    final existing = DatabaseService.booksBox.get(id);
    try {
      await DatabaseService.booksBox.delete(id);
    } catch (e, st) {
      debugPrint('Failed to delete book $id: $e\n$st');
      rethrow;
    }
    if (existing != null) {
      try {
        final subj = DatabaseService.subjectsBox.get(existing.subjectId);
        if (subj != null && subj.bookIds.contains(id)) {
          subj.bookIds.remove(id);
          await DatabaseService.subjectsBox.put(subj.id, subj);
        }
      } catch (_) {}
    }
    _loadBooks();
  }

  /// Get book by ID
  Book? getBookById(int id) {
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all books for a subject
  List<Book> getBooksForSubject(int subjectId) {
    return _books.where((b) => b.subjectId == subjectId).toList();
  }

  /// Generate QR code string for a book
  String generateQrCodeForBook(Book book, String subjectName) {
    return book.generateQrCode(subjectName);
  }

  /// Refresh books from database
  void refresh() {
    _loadBooks();
  }

  /// Get the current status for a book ('available'|'missing'|'handed_in')
  String getBookStatus(int bookId) {
    try {
      final map = Map<String, dynamic>.from(
          DatabaseService.settingsBox.get('bookStatuses', defaultValue: {}) as Map);
      return map['$bookId'] as String? ?? 'available';
    } catch (_) {
      return 'available';
    }
  }

  /// Set a status for a book and notify listeners so UI can update
  Future<void> setBookStatus(int bookId, String status) async {
    final box = DatabaseService.settingsBox;
    final existing = Map<String, dynamic>.from(
        box.get('bookStatuses', defaultValue: {}) as Map);
    existing['$bookId'] = status;
    await box.put('bookStatuses', existing);
    notifyListeners();
  }

  /// Convenience helpers
  Future<void> markBookMissing(int bookId) async => setBookStatus(bookId, 'missing');
  Future<void> markBookHandedIn(int bookId) async => setBookStatus(bookId, 'handed_in');

  /// Public repair method: ensure that each Subject.bookIds reflects current books
  /// Returns the number of subjects that were updated.
  Future<int> repairSubjectBookMappings() async {
    int updated = 0;
    try {
      final allBooks = DatabaseService.booksBox.values.toList();
      final subjects = DatabaseService.subjectsBox.values.toList();

      for (final subj in subjects) {
        final ids = allBooks.where((b) => b.subjectId == subj.id).map((b) => b.id).toList();
        if (!(ListEquality().equals(ids, subj.bookIds))) {
          subj.bookIds
            ..clear()
            ..addAll(ids);
          await DatabaseService.subjectsBox.put(subj.id, subj);
          updated++;
        }
      }
    } catch (_) {}

    // Refresh local cache and listeners
    _loadBooks();
    return updated;
  }

  /// Public repair method: sanitize `bookStatuses` in settingsBox.
  /// Removes statuses for non-existent books and ensures every existing book
  /// has an explicit status (defaults to 'available'). Returns a map with counts.
  Future<Map<String, int>> repairBookStatuses() async {
    final result = <String, int>{'removed': 0, 'added': 0};
    try {
      final box = DatabaseService.settingsBox;
      final existing = Map<String, dynamic>.from(box.get('bookStatuses', defaultValue: {}) as Map);
      final bookIds = DatabaseService.booksBox.keys.cast<int>().toSet();

      final newMap = <String, String>{};

      for (final id in bookIds) {
        final key = '$id';
        if (existing.containsKey(key)) {
          newMap[key] = existing[key] as String;
        } else {
          newMap[key] = 'available';
          result['added'] = (result['added'] ?? 0) + 1;
        }
      }

      // Count removals
      for (final key in existing.keys.map((k) => k.toString())) {
        final intKey = int.tryParse(key);
        if (intKey == null || !bookIds.contains(intKey)) {
          result['removed'] = (result['removed'] ?? 0) + 1;
        }
      }

      await box.put('bookStatuses', newMap);
      notifyListeners();
    } catch (_) {}

    return result;
  }

  /// Run all repair routines and return a summary map.
  Future<Map<String, dynamic>> runAllRepairs() async {
    final updatedSubjects = await repairSubjectBookMappings();
    final statusResult = await repairBookStatuses();
    return {
      'updatedSubjects': updatedSubjects,
      'statusesRemoved': statusResult['removed'] ?? 0,
      'statusesAdded': statusResult['added'] ?? 0,
    };
  }

  /// Recreate missing Book records for any IDs referenced in Subject.bookIds
  /// Returns number of books created.
  Future<int> recreateMissingBooksFromSubjects() async {
    int created = 0;
    try {
      final subjects = DatabaseService.subjectsBox.values.toList();
      final existingIds = DatabaseService.booksBox.keys.cast<int>().toSet();

      for (final subj in subjects) {
        for (final id in subj.bookIds) {
          if (!existingIds.contains(id)) {
            final book = Book(id: id, subjectId: subj.id, description: null);
            try {
              await DatabaseService.booksBox.put(book.id, book);
              created++;
              existingIds.add(id);
            } catch (e, st) {
              debugPrint('Failed to recreate book $id for subject ${subj.id}: $e\n$st');
            }
          }
        }
      }
    } catch (e, st) {
      debugPrint('Error recreating missing books: $e\n$st');
    }
    _loadBooks();
    return created;
  }
}
