import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

/// Screen for batch operations on subjects
class SubjectsBatchScreen extends StatefulWidget {
  const SubjectsBatchScreen({super.key});

  @override
  State<SubjectsBatchScreen> createState() => _SubjectsBatchScreenState();
}

class _SubjectsBatchScreenState extends State<SubjectsBatchScreen> {
  final Set<int> _selectedIds = {};
  String _searchQuery = '';

  bool get _hasSelection => _selectedIds.isNotEmpty;
  int get _selectedCount => _selectedIds.length;

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<Subject> subjects) {
    setState(() {
      _selectedIds.addAll(subjects.map((s) => s.id));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subjects'),
        content: Text(
          'Delete $_selectedCount selected subject${_selectedCount > 1 ? 's' : ''}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final subjectService = context.read<SubjectService>();
      final messenger = ScaffoldMessenger.of(context);
      for (final id in _selectedIds) {
        await subjectService.deleteSubject(id);
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Deleted $_selectedCount subject${_selectedCount > 1 ? 's' : ''}',
          ),
        ),
      );
      _clearSelection();
    }
  }

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

        return Scaffold(
          appBar: AppBar(
            title: _hasSelection
                ? Text('$_selectedCount selected')
                : const Text('Batch Operations'),
            leading: _hasSelection
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearSelection,
                  )
                : null,
            actions: _hasSelection
                ? [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete Selected',
                      onPressed: () => _deleteSelected(context),
                    ),
                  ]
                : [
                    if (subjects.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.select_all),
                        tooltip: 'Select All',
                        onPressed: () => _selectAll(subjects),
                      ),
                  ],
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search subjects...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                ),
              ),

              // Info banner
              if (!_hasSelection)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tap subjects to select them for batch operations',
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

              // Results
              Expanded(
                child: subjects.isEmpty
                    ? const EmptyState(
                        icon: Icons.subject_outlined,
                        title: 'No subjects found',
                        subtitle: 'Try a different search term',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          final isSelected = _selectedIds.contains(subject.id);

                          return Card(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (_) => _toggleSelection(subject.id),
                              title: Text(
                                subject.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('ID: ${subject.id}'),
                              secondary: ColorAvatar(
                                color: subject.colorValue != null
                                    ? Color(subject.colorValue!)
                                    : Colors.grey,
                                text: subject.name,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
