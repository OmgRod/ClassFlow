import 'package:flutter/material.dart';

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

  /// Get display color from colorValue or generate from name
  int get displayColor {
    if (colorValue != null) return colorValue!;
    // Generate color from name hash
    final hash = name.hashCode;
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor().toARGB32();
  }

  /// Get display initials (first 2 letters)
  String get displayInitials {
    if (name.isEmpty) return '??';
    if (name.length == 1) return name;
    return name.substring(0, 2);
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
