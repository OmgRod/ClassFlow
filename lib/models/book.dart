class Book {
  int id;
  int subjectId;
  String? description;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as int,
      subjectId: json['subjectId'] as int,
      description: json['description'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}
