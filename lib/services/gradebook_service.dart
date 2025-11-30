import 'package:flutter/foundation.dart';
import '../models/grade.dart';

/// Service for managing grades and calculating GPAs
class GradebookService extends ChangeNotifier {
  final List<Grade> _grades = [];
  final Map<int, List<GradeCategory>> _categoriesBySubject = {};

  List<Grade> get grades => List.unmodifiable(_grades);

  /// Get grades for a specific subject
  List<Grade> getGradesForSubject(int subjectId) {
    return _grades.where((g) => g.subjectId == subjectId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get categories for a subject
  List<GradeCategory> getCategoriesForSubject(int subjectId) {
    return _categoriesBySubject[subjectId] ?? [];
  }

  /// Add a new grade
  Future<void> addGrade(Grade grade) async {
    _grades.add(grade);
    notifyListeners();
  }

  /// Update an existing grade
  Future<void> updateGrade(Grade grade) async {
    final index = _grades.indexWhere((g) => g.id == grade.id);
    if (index != -1) {
      _grades[index] = grade;
      notifyListeners();
    }
  }

  /// Delete a grade
  Future<void> deleteGrade(int id) async {
    _grades.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  /// Set categories for a subject
  Future<void> setCategoriesForSubject(
    int subjectId,
    List<GradeCategory> categories,
  ) async {
    _categoriesBySubject[subjectId] = categories;
    notifyListeners();
  }

  /// Calculate weighted average for a subject
  double calculateSubjectAverage(int subjectId) {
    final subjectGrades = getGradesForSubject(subjectId);
    if (subjectGrades.isEmpty) return 0.0;

    final categories = getCategoriesForSubject(subjectId);
    if (categories.isEmpty) {
      // Simple average if no categories defined
      final total = subjectGrades.fold<double>(
        0,
        (sum, g) => sum + g.percentage,
      );
      return total / subjectGrades.length;
    }

    // Weighted average by category
    double weightedSum = 0;
    double totalWeight = 0;

    for (final category in categories) {
      final categoryGrades = subjectGrades
          .where((g) => g.category == category.name)
          .toList();
      if (categoryGrades.isNotEmpty) {
        final categoryAvg =
            categoryGrades.fold<double>(0, (sum, g) => sum + g.percentage) /
            categoryGrades.length;
        weightedSum += categoryAvg * category.weight;
        totalWeight += category.weight;
      }
    }

    return totalWeight > 0 ? weightedSum / totalWeight : 0.0;
  }

  /// Calculate overall GPA (4.0 scale)
  double calculateGPA() {
    final subjectIds = _grades.map((g) => g.subjectId).toSet();
    if (subjectIds.isEmpty) return 0.0;

    double totalPoints = 0;
    int subjectCount = 0;

    for (final subjectId in subjectIds) {
      final avg = calculateSubjectAverage(subjectId);
      totalPoints += _percentageToGPA(avg);
      subjectCount++;
    }

    return subjectCount > 0 ? totalPoints / subjectCount : 0.0;
  }

  /// Convert percentage to GPA point (4.0 scale)
  double _percentageToGPA(double percentage) {
    if (percentage >= 93) return 4.0;
    if (percentage >= 90) return 3.7;
    if (percentage >= 87) return 3.3;
    if (percentage >= 83) return 3.0;
    if (percentage >= 80) return 2.7;
    if (percentage >= 77) return 2.3;
    if (percentage >= 73) return 2.0;
    if (percentage >= 70) return 1.7;
    if (percentage >= 67) return 1.3;
    if (percentage >= 65) return 1.0;
    return 0.0;
  }

  /// Get letter grade from percentage
  String getLetterGrade(double percentage) {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  /// Get statistics for a subject
  GradeStatistics getSubjectStatistics(int subjectId) {
    final subjectGrades = getGradesForSubject(subjectId);
    if (subjectGrades.isEmpty) {
      return GradeStatistics(
        average: 0,
        highest: 0,
        lowest: 0,
        count: 0,
        letterGrade: 'N/A',
      );
    }

    final percentages = subjectGrades.map((g) => g.percentage).toList();
    final average = calculateSubjectAverage(subjectId);

    return GradeStatistics(
      average: average,
      highest: percentages.reduce((a, b) => a > b ? a : b),
      lowest: percentages.reduce((a, b) => a < b ? a : b),
      count: subjectGrades.length,
      letterGrade: getLetterGrade(average),
    );
  }

  /// Get trend data for charts (last N grades)
  List<GradeTrendPoint> getTrendData(int subjectId, {int limit = 10}) {
    final subjectGrades = getGradesForSubject(subjectId);
    final limited = subjectGrades.take(limit).toList().reversed.toList();

    return limited
        .map(
          (g) => GradeTrendPoint(
            date: g.date,
            percentage: g.percentage,
            name: g.name,
          ),
        )
        .toList();
  }

  /// Generate next grade ID
  int _generateId() {
    if (_grades.isEmpty) return 1;
    return _grades.map((g) => g.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Create a new grade with auto-generated ID
  Grade createGrade({
    required int subjectId,
    required String name,
    required double score,
    required double maxScore,
    required String category,
    DateTime? date,
    String? notes,
  }) {
    return Grade(
      id: _generateId(),
      subjectId: subjectId,
      name: name,
      score: score,
      maxScore: maxScore,
      category: category,
      date: date ?? DateTime.now(),
      notes: notes,
    );
  }

  /// Get default categories
  static List<GradeCategory> getDefaultCategories() {
    return [
      GradeCategory(
        name: 'Homework',
        weight: 0.2,
        description: 'Homework assignments',
      ),
      GradeCategory(
        name: 'Quizzes',
        weight: 0.2,
        description: 'Pop quizzes and short tests',
      ),
      GradeCategory(
        name: 'Tests',
        weight: 0.4,
        description: 'Major tests and exams',
      ),
      GradeCategory(name: 'Final', weight: 0.2, description: 'Final exam'),
    ];
  }
}

class GradeStatistics {
  final double average;
  final double highest;
  final double lowest;
  final int count;
  final String letterGrade;

  GradeStatistics({
    required this.average,
    required this.highest,
    required this.lowest,
    required this.count,
    required this.letterGrade,
  });
}

class GradeTrendPoint {
  final DateTime date;
  final double percentage;
  final String name;

  GradeTrendPoint({
    required this.date,
    required this.percentage,
    required this.name,
  });
}
