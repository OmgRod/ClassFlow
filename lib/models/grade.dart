/// Model for grade entries in the gradebook
class Grade {
  final int id;
  final int subjectId;
  final String name;
  final double score;
  final double maxScore;
  final String category;
  final DateTime date;
  final String? notes;

  Grade({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.score,
    required this.maxScore,
    required this.category,
    required this.date,
    this.notes,
  });

  /// Calculate percentage score
  double get percentage => (score / maxScore) * 100;

  /// Get letter grade (A-F)
  String get letterGrade {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'name': name,
    'score': score,
    'maxScore': maxScore,
    'category': category,
    'date': date.toIso8601String(),
    'notes': notes,
  };

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
    id: json['id'] as int,
    subjectId: json['subjectId'] as int,
    name: json['name'] as String,
    score: (json['score'] as num).toDouble(),
    maxScore: (json['maxScore'] as num).toDouble(),
    category: json['category'] as String,
    date: DateTime.parse(json['date'] as String),
    notes: json['notes'] as String?,
  );

  Grade copyWith({
    int? id,
    int? subjectId,
    String? name,
    double? score,
    double? maxScore,
    String? category,
    DateTime? date,
    String? notes,
  }) => Grade(
    id: id ?? this.id,
    subjectId: subjectId ?? this.subjectId,
    name: name ?? this.name,
    score: score ?? this.score,
    maxScore: maxScore ?? this.maxScore,
    category: category ?? this.category,
    date: date ?? this.date,
    notes: notes ?? this.notes,
  );
}

/// Model for grade category with weight
class GradeCategory {
  final String name;
  final double weight; // 0.0 to 1.0 (e.g., 0.3 for 30%)
  final String? description;

  GradeCategory({required this.name, required this.weight, this.description});

  Map<String, dynamic> toJson() => {
    'name': name,
    'weight': weight,
    'description': description,
  };

  factory GradeCategory.fromJson(Map<String, dynamic> json) => GradeCategory(
    name: json['name'] as String,
    weight: (json['weight'] as num).toDouble(),
    description: json['description'] as String?,
  );
}
