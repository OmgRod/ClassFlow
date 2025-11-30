import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/services.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

/// Screen for viewing and managing grades
class GradebookScreen extends StatefulWidget {
  const GradebookScreen({super.key});

  @override
  State<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends State<GradebookScreen> {
  int? _selectedSubjectId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gradebook'),
        actions: [
          if (_selectedSubjectId != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddGradeDialog(),
              tooltip: 'Add Grade',
            ),
        ],
      ),
      body: MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => GradebookService())],
        child: Column(
          children: [
            // Subject selector
            _buildSubjectSelector(),

            // GPA overview
            Consumer<GradebookService>(
              builder: (context, gradebook, child) {
                final gpa = gradebook.calculateGPA();
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.secondaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        context,
                        'Overall GPA',
                        gpa.toStringAsFixed(2),
                        Icons.school,
                      ),
                      if (_selectedSubjectId != null) const VerticalDivider(),
                      if (_selectedSubjectId != null)
                        _buildStatCard(
                          context,
                          'Subject Average',
                          '${gradebook.calculateSubjectAverage(_selectedSubjectId!).toStringAsFixed(1)}%',
                          Icons.trending_up,
                        ),
                    ],
                  ),
                );
              },
            ),

            // Grades list
            Expanded(
              child: _selectedSubjectId == null
                  ? const EmptyState(
                      icon: Icons.grade,
                      title: 'Select a subject',
                      subtitle: 'Choose a subject to view grades',
                    )
                  : _buildGradesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSelector() {
    return Consumer<SubjectService>(
      builder: (context, subjectService, child) {
        final subjects = subjectService.subjects;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<int>(
            value: _selectedSubjectId,
            hint: const Text('Select Subject'),
            isExpanded: true,
            underline: const SizedBox(),
            items: subjects.map((subject) {
              return DropdownMenuItem(
                value: subject.id,
                child: Row(
                  children: [
                    ColorAvatar(
                      color: Color(subject.displayColor),
                      text: subject.name,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(subject.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (id) {
              setState(() => _selectedSubjectId = id);
            },
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildGradesList() {
    return Consumer<GradebookService>(
      builder: (context, gradebook, child) {
        final grades = gradebook.getGradesForSubject(_selectedSubjectId!);

        if (grades.isEmpty) {
          return const EmptyState(
            icon: Icons.grade,
            title: 'No grades yet',
            subtitle: 'Tap + to add your first grade',
          );
        }

        // Group by category
        final categories = grades.map((g) => g.category).toSet().toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final categoryGrades = grades
                .where((g) => g.category == category)
                .toList();

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ...categoryGrades.map((grade) => _buildGradeItem(grade)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGradeItem(Grade grade) {
    final percentage = grade.percentage;
    final color = percentage >= 90
        ? Colors.green
        : percentage >= 80
        ? Colors.blue
        : percentage >= 70
        ? Colors.orange
        : Colors.red;

    return ListTile(
      title: Text(grade.name),
      subtitle: Text(
        '${grade.score}/${grade.maxScore} • ${grade.date.toString().split(' ')[0]}',
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
      onTap: () => _showGradeDetails(grade),
    );
  }

  void _showAddGradeDialog() {
    final nameController = TextEditingController();
    final scoreController = TextEditingController();
    final maxScoreController = TextEditingController(text: '100');
    String category = 'Homework';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Grade'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Assignment Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: scoreController,
                      decoration: const InputDecoration(
                        labelText: 'Score',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('/', style: TextStyle(fontSize: 20)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: maxScoreController,
                      decoration: const InputDecoration(
                        labelText: 'Max Score',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ['Homework', 'Quizzes', 'Tests', 'Final', 'Project']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) category = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  scoreController.text.isNotEmpty &&
                  maxScoreController.text.isNotEmpty) {
                final gradebook = context.read<GradebookService>();
                final grade = gradebook.createGrade(
                  subjectId: _selectedSubjectId!,
                  name: nameController.text,
                  score: double.parse(scoreController.text),
                  maxScore: double.parse(maxScoreController.text),
                  category: category,
                );
                gradebook.addGrade(grade);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showGradeDetails(Grade grade) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(grade.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Score', '${grade.score}/${grade.maxScore}'),
            _buildDetailRow(
              'Percentage',
              '${grade.percentage.toStringAsFixed(1)}%',
            ),
            _buildDetailRow('Letter Grade', grade.letterGrade),
            _buildDetailRow('Category', grade.category),
            _buildDetailRow('Date', grade.date.toString().split(' ')[0]),
            if (grade.notes != null) _buildDetailRow('Notes', grade.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<GradebookService>().deleteGrade(grade.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
