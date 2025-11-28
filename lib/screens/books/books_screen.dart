import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import 'qr_code_screen.dart';
import '../../services/qr_pdf_service.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  // Selection key: "<subjectId>:<bookId>"
  final Set<String> _selected = {};
  double _scale = 0.2; // fraction of page width for each QR

  String _keyFor(int subjectId, int bookId) => '$subjectId:$bookId';

  void _selectAllForSubjects(List<Subject> subjects) {
    setState(() {
      _selected
        ..clear()
        ..addAll(
          subjects.expand((s) => s.bookIds.map((b) => _keyFor(s.id, b))),
        );
    });
  }

  void _toggleSelection(int subjectId, int bookId) {
    final k = _keyFor(subjectId, bookId);
    setState(() {
      if (_selected.contains(k))
        _selected.remove(k);
      else
        _selected.add(k);
    });
  }

  Future<void> _exportSelected(List<Map<String, String>> items) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setStateModal) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Export QR Codes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Scale:'),
                    Expanded(
                      child: Slider(
                        min: 0.12,
                        max: 0.45,
                        divisions: 10,
                        value: _scale,
                        label: '${(_scale * 100).round()}% of page width',
                        onChanged: (v) => setStateModal(() => _scale = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await QrPdfService.generateAndShare(
                          items,
                          scale: _scale,
                        );
                      },
                      child: const Text('Generate & Share'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubjectService, BookService>(
      builder: (context, subjectService, bookService, child) {
        final subjects = subjectService.subjects;

        if (subjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No subjects with books',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                const Text('Add subjects with books first'),
              ],
            ),
          );
        }

        // Group books by subject
        final subjectsWithBooks = subjects
            .where((s) => s.bookIds.isNotEmpty)
            .toList();

        if (subjectsWithBooks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No books added',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                const Text('Add book IDs to your subjects'),
              ],
            ),
          );
        }

        // Build list of items for export convenience
        List<Map<String, String>> selectedItems() {
          final out = <Map<String, String>>[];
          for (final key in _selected) {
            final parts = key.split(':');
            final sid = int.tryParse(parts[0]);
            final bid = int.tryParse(parts[1]);
            if (sid == null || bid == null) continue;
            final subj = subjectService.getSubjectById(sid);
            if (subj == null) continue;
            out.add({
              'code': subj.generateCode(bid),
              'label': '${subj.name} - $bid',
            });
          }
          return out;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Books'),
            actions: [
              if (subjectsWithBooks.isNotEmpty)
                IconButton(
                  icon: Icon(
                    _selected.length ==
                            subjectsWithBooks.expand((s) => s.bookIds).length
                        ? Icons.select_all
                        : Icons.done_all,
                  ),
                  tooltip: _selected.isEmpty
                      ? 'Select all books'
                      : 'Clear selection',
                  onPressed: () {
                    if (_selected.isEmpty) {
                      _selectAllForSubjects(subjectsWithBooks);
                    } else {
                      setState(() => _selected.clear());
                    }
                  },
                ),
              if (_selected.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Export selected QR codes',
                  onPressed: () async {
                    final items = selectedItems();
                    if (items.isEmpty) return;
                    await _exportSelected(items);
                  },
                ),
            ],
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subjectsWithBooks.length,
            itemBuilder: (context, index) {
              final subject = subjectsWithBooks[index];
              return _SubjectBooksCard(
                subject: subject,
                selectedSet: _selected,
                onToggle: _toggleSelection,
              );
            },
          ),
        );
      },
    );
  }
}

class _SubjectBooksCard extends StatelessWidget {
  final Subject subject;
  final Set<String> selectedSet;
  final void Function(int subjectId, int bookId) onToggle;

  const _SubjectBooksCard({
    required this.subject,
    required this.selectedSet,
    required this.onToggle,
  });

  String _keyFor(int subjectId, int bookId) => '$subjectId:$bookId';

  @override
  Widget build(BuildContext context) {
    final bookService = context.watch<BookService>();
    final color = subject.colorValue != null
        ? Color(subject.colorValue!)
        : AppColors.getDefaultSubjectColor(subject.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      subject.name.isNotEmpty ? subject.name[0] : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${subject.bookIds.length} book(s)',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Books list
          ...subject.bookIds.map((bookId) {
            final code = subject.generateCode(bookId);
            final status = bookService.getBookStatus(subject.id, bookId);
            Color statusColor;
            String statusLabel;
            switch (status) {
              case 'missing':
                statusColor = Colors.red.shade400;
                statusLabel = 'Missing';
                break;
              case 'handed_in':
                statusColor = Colors.orange.shade700;
                statusLabel = 'Handed in';
                break;
              default:
                statusColor = Colors.green.shade600;
                statusLabel = 'Available';
            }

            final key = _keyFor(subject.id, bookId);

            return ListTile(
              selected: selectedSet.contains(key),
              tileColor: selectedSet.contains(key) ? Colors.blue.shade50 : null,
              onTap: () => onToggle(subject.id, bookId),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selectedSet.contains(key)
                      ? Colors.blue.shade100
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selectedSet.contains(key)
                        ? Colors.blue
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: selectedSet.contains(key)
                    ? const Icon(Icons.check, color: Colors.blue)
                    : const Icon(Icons.qr_code),
              ),
              title: Text('Book ID: $bookId'),
              subtitle: Text(
                code,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      final bookService = context.read<BookService>();
                      switch (value) {
                        case 'available':
                          bookService.setBookStatus(
                            subject.id,
                            bookId,
                            'available',
                          );
                          break;
                        case 'handed_in':
                          bookService.markBookHandedIn(subject.id, bookId);
                          break;
                        case 'missing':
                          bookService.markBookMissing(subject.id, bookId);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'available',
                        child: Text('Available'),
                      ),
                      const PopupMenuItem(
                        value: 'handed_in',
                        child: Text('Handed in'),
                      ),
                      const PopupMenuItem(
                        value: 'missing',
                        child: Text('Missing'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.9)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 18),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_2),
                    tooltip: 'View QR Code',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              QrCodeScreen(subject: subject, bookId: bookId),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
