import 'package:hive/hive.dart';

part 'book.g.dart';

@HiveType(typeId: 1)
class Book extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int subjectId;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime createdAt;

  Book({
    required this.id,
    required this.subjectId,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Generate QR code string: [subjectID]-[bookID]-[FULLNAME]
  /// The subjectName should be passed from the Subject model
  String generateQrCode(String subjectName) {
    return '$subjectId-$id-$subjectName';
  }

  Book copyWith({
    int? id,
    int? subjectId,
    String? description,
    DateTime? createdAt,
  }) {
    return Book(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Book(id: $id, subjectId: $subjectId, description: $description)';
  }
}
