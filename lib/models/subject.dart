class Subject {
  int id;
  String name; // Full uppercase, no spaces
  List<int> bookIds;
  int? colorValue; // ARGB color value for GUI highlighting

  Subject({
    required this.id,
    required this.name,
    List<int>? bookIds,
    this.colorValue,
  }) : bookIds = bookIds ?? [];

  /// Auto-generated code: [subjectID]-[bookID]-[FULLNAME]
  String generateCode(int bookId) {
    return '$id-$bookId-$name';
  }

  /// Get all codes for this subject (one per book)
  List<String> get allCodes {
    return bookIds.map((bookId) => generateCode(bookId)).toList();
  }

  /// Validate and format name (uppercase, no spaces)
  static String formatName(String input) {
    return input.toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }

  /// Check if name is valid (uppercase, no spaces)
  static bool isValidName(String name) {
    return name == name.toUpperCase() && !name.contains(' ');
  }

  Subject copyWith({
    int? id,
    String? name,
    List<int>? bookIds,
    int? colorValue,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      bookIds: bookIds ?? List.from(this.bookIds),
      colorValue: colorValue ?? this.colorValue,
    );
  }

  @override
  String toString() {
    return 'Subject(id: $id, name: $name, bookIds: $bookIds, colorValue: $colorValue)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bookIds': bookIds,
      'colorValue': colorValue,
    };
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as int,
      name: json['name'] as String,
      bookIds: (json['bookIds'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
      colorValue: json['colorValue'] as int?,
    );
  }
}
