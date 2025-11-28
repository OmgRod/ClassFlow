import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import '../models/models.dart';
import 'database_service.dart';

class BookService extends ChangeNotifier {
  List<Book> _books = [];

  List<Book> get books => _books;

  BookService() {
    _loadBooks();
  }

  void _loadBooks() {
    _books = List<Book>.from(DatabaseService.books);
    try {
      debugPrint('BookService: loaded ${_books.length} books from JSON db');
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
      DatabaseService.books.removeWhere((b) => b.id == book.id);
      DatabaseService.books.add(book);
      await DatabaseService.save();
    } catch (e, st) {
      debugPrint('Failed to persist book ${book.id}: $e\n$st');
      rethrow;
    }
    // Ensure the subject knows about this book ID
    try {
      final subj = DatabaseService.subjects.firstWhereOrNull(
        (s) => s.id == subjectId,
      );
      if (subj != null && !subj.bookIds.contains(book.id)) {
        subj.bookIds.add(book.id);
        await DatabaseService.save();
      }
    } catch (_) {}

    _loadBooks();
    return book;
  }

  /// Update an existing book
  Future<void> updateBook(Book book) async {
    // Get existing book to detect subject change
    final existing = DatabaseService.books.firstWhereOrNull(
      (b) => b.id == book.id,
    );
    try {
      final index = DatabaseService.books.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        DatabaseService.books[index] = book;
      } else {
        DatabaseService.books.add(book);
      }
      await DatabaseService.save();
    } catch (e, st) {
      debugPrint('Failed to update book ${book.id}: $e\n$st');
      rethrow;
    }

    if (existing != null && existing.subjectId != book.subjectId) {
      // Remove from old subject
      try {
        final oldSubj = DatabaseService.subjects.firstWhereOrNull(
          (s) => s.id == existing.subjectId,
        );
        if (oldSubj != null && oldSubj.bookIds.contains(book.id)) {
          oldSubj.bookIds.remove(book.id);
          await DatabaseService.save();
        }
      } catch (_) {}
      // Add to new subject
      try {
        final newSubj = DatabaseService.subjects.firstWhereOrNull(
          (s) => s.id == book.subjectId,
        );
        if (newSubj != null && !newSubj.bookIds.contains(book.id)) {
          newSubj.bookIds.add(book.id);
          await DatabaseService.save();
        }
      } catch (_) {}
    }

    _loadBooks();
  }

  /// Delete a book
  Future<void> deleteBook(int id) async {
    // Remove book and update subject mapping
    final existing = DatabaseService.books.firstWhereOrNull((b) => b.id == id);
    try {
      DatabaseService.books.removeWhere((b) => b.id == id);
      await DatabaseService.save();
    } catch (e, st) {
      debugPrint('Failed to delete book $id: $e\n$st');
      rethrow;
    }
    if (existing != null) {
      try {
        final subj = DatabaseService.subjects.firstWhereOrNull(
          (s) => s.id == existing.subjectId,
        );
        if (subj != null && subj.bookIds.contains(id)) {
          subj.bookIds.remove(id);
          await DatabaseService.save();
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
      final raw = DatabaseService.settings['bookStatuses'];
      final map = raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      return map['$bookId'] as String? ?? 'available';
    } catch (_) {
      return 'available';
    }
  }

  /// Set a status for a book and notify listeners so UI can update
  Future<void> setBookStatus(int bookId, String status) async {
    final raw = DatabaseService.settings['bookStatuses'];
    final existing = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    existing['$bookId'] = status;
    DatabaseService.settings['bookStatuses'] = existing;
    await DatabaseService.save();
    notifyListeners();
  }

  /// Convenience helpers
  Future<void> markBookMissing(int bookId) async =>
      setBookStatus(bookId, 'missing');
  Future<void> markBookHandedIn(int bookId) async =>
      setBookStatus(bookId, 'handed_in');

  /// Public repair method: ensure that each Subject.bookIds reflects current books
  /// Returns the number of subjects that were updated.
  Future<int> repairSubjectBookMappings() async {
    final allBooks = List<Book>.from(DatabaseService.books);
    final subjects = DatabaseService.subjects;
    int updated = 0;
    try {
      for (final subj in subjects) {
        final ids = allBooks
            .where((b) => b.subjectId == subj.id)
            .map((b) => b.id)
            .toList();
        if (!(ListEquality().equals(ids, subj.bookIds))) {
          subj.bookIds
            ..clear()
            ..addAll(ids);
          updated++;
        }
      }

      await DatabaseService.save();
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
      final raw = DatabaseService.settings['bookStatuses'];
      final existing = raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      final bookIds = DatabaseService.books.map((b) => b.id).toSet();

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

      DatabaseService.settings['bookStatuses'] = newMap;
      await DatabaseService.save();
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
      final subjects = DatabaseService.subjects;
      final existingIds = DatabaseService.books.map((b) => b.id).toSet();

      for (final subj in subjects) {
        for (final id in subj.bookIds) {
          if (!existingIds.contains(id)) {
            final book = Book(id: id, subjectId: subj.id, description: null);
            try {
              DatabaseService.books.add(book);
              created++;
              existingIds.add(id);
              await DatabaseService.save();
            } catch (e, st) {
              debugPrint(
                'Failed to recreate book $id for subject ${subj.id}: $e\n$st',
              );
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
