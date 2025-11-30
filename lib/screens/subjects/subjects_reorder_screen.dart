import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

class SubjectsReorderScreen extends StatefulWidget {
  const SubjectsReorderScreen({super.key});

  @override
  State<SubjectsReorderScreen> createState() => _SubjectsReorderScreenState();
}

class _SubjectsReorderScreenState extends State<SubjectsReorderScreen> {
  late List<Subject> _subjects;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final subjectService = context.read<SubjectService>();
    _subjects = List<Subject>.from(subjectService.subjects);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showDiscardDialog();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reorder Subjects'),
          actions: [
            if (_hasChanges)
              TextButton(onPressed: _saveOrder, child: const Text('Save')),
          ],
        ),
        body: _subjects.isEmpty
            ? const EmptyState(
                icon: Icons.subject_outlined,
                title: 'No subjects to reorder',
                subtitle: 'Add some subjects first',
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Long press and drag to reorder subjects',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _subjects.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          _hasChanges = true;
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final subject = _subjects.removeAt(oldIndex);
                          _subjects.insert(newIndex, subject);
                        });
                      },
                      itemBuilder: (context, index) {
                        final subject = _subjects[index];
                        return Card(
                          key: ValueKey(subject.id),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: ColorAvatar(
                              color: Color(subject.displayColor),
                              text: subject.displayInitials,
                            ),
                            title: Text(
                              subject.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'ID: ${subject.id} • ${subject.bookIds.length} book(s)',
                            ),
                            trailing: ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Do you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _saveOrder() async {
    final subjectService = context.read<SubjectService>();
    await subjectService.reorderSubjects(_subjects);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Subject order saved')));
      Navigator.pop(context);
    }
  }
}
