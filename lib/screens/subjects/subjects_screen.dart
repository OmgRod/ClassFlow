import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/widgets.dart';
import 'subject_form_screen.dart';
import 'subjects_batch_screen.dart';
import 'subjects_reorder_screen.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<SubjectService>(
      builder: (context, subjectService, child) {
        final allSubjects = subjectService.subjects;
        final subjects = _searchQuery.isEmpty
            ? allSubjects
            : allSubjects
                  .where(
                    (s) =>
                        s.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        s.id.toString().contains(_searchQuery),
                  )
                  .toList();

        if (allSubjects.isEmpty) {
          return EmptyState(
            icon: Icons.subject_outlined,
            title: 'No subjects yet',
            subtitle: 'Tap + to add your first subject',
            action: ElevatedButton.icon(
              onPressed: () => _navigateToAddSubject(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Subject'),
            ),
          );
        }

        return Stack(
          children: [
            Column(
              children: [
                // Search bar and batch operations
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search subjects...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () =>
                                        setState(() => _searchQuery = ''),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.checklist),
                        tooltip: 'Batch Operations',
                        onPressed: () => _navigateToBatchOperations(context),
                      ),
                      IconButton.filled(
                        icon: const Icon(Icons.reorder),
                        tooltip: 'Reorder Subjects',
                        onPressed: () => _navigateToReorder(context),
                      ),
                    ],
                  ),
                ),
                // Results
                Expanded(
                  child: subjects.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off,
                          title: 'No subjects found',
                          subtitle: 'Try a different search term',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: subjects.length,
                          itemBuilder: (context, index) {
                            final subject = subjects[index];
                            return _SubjectCard(
                              subject: subject,
                              onTap: () =>
                                  _navigateToEditSubject(context, subject),
                              onDelete: () => _confirmDelete(
                                context,
                                subject,
                                subjectService,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                tooltip: 'Add Subject',
                onPressed: () => _navigateToAddSubject(context),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddSubject(BuildContext context) {
    Navigator.push(context, SlidePageRoute(page: const SubjectFormScreen()));
  }

  void _navigateToEditSubject(BuildContext context, Subject subject) {
    Navigator.push(
      context,
      SlidePageRoute(page: SubjectFormScreen(subject: subject)),
    );
  }

  void _navigateToBatchOperations(BuildContext context) {
    Navigator.push(context, SlidePageRoute(page: const SubjectsBatchScreen()));
  }

  void _navigateToReorder(BuildContext context) {
    Navigator.push(
      context,
      SlidePageRoute(page: const SubjectsReorderScreen()),
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
              ColorAvatar(
                color: color,
                text: subject.name.isNotEmpty ? subject.name[0] : '?',
                size: 50,
                fontSize: 20,
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
