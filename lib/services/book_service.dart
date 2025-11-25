import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'database_service.dart';

class BookService extends ChangeNotifier {
  List<Book> _books = [];

  List<Book> get books => _books;

  BookService() {
    _loadBooks();
  }

  void _loadBooks() {
    _books = DatabaseService.booksBox.values.toList();
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
    await DatabaseService.booksBox.put(book.id, book);
    _loadBooks();
    return book;
  }

  /// Update an existing book
  Future<void> updateBook(Book book) async {
    await DatabaseService.booksBox.put(book.id, book);
    _loadBooks();
  }

  /// Delete a book
  Future<void> deleteBook(int id) async {
    await DatabaseService.booksBox.delete(id);
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
}
