import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import 'subject_form_screen.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SubjectService>(
      builder: (context, subjectService, child) {
        final subjects = subjectService.subjects;

        if (subjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.subject_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No subjects yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Tap + to add your first subject'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _navigateToAddSubject(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Subject'),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return _SubjectCard(
                  subject: subject,
                  onTap: () => _navigateToEditSubject(context, subject),
                  onDelete: () => _confirmDelete(context, subject, subjectService),
                );
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () => _navigateToAddSubject(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Subject'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddSubject(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubjectFormScreen(),
      ),
    );
  }

  void _navigateToEditSubject(BuildContext context, Subject subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectFormScreen(subject: subject),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Subject subject,
    SubjectService subjectService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
          'Are you sure you want to delete "${subject.name}"?\n\n'
          'This will also delete all associated books and lessons.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              subjectService.deleteSubject(subject.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${subject.name} deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SubjectCard({
    required this.subject,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = subject.colorValue != null
        ? Color(subject.colorValue!)
        : AppColors.getDefaultSubjectColor(subject.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Text(
                    subject.name.isNotEmpty ? subject.name[0] : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${subject.id} • ${subject.bookIds.length} book(s)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (subject.bookIds.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Codes: ${subject.allCodes.join(", ")}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
