import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import 'qr_code_screen.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subjectsWithBooks.length,
          itemBuilder: (context, index) {
            final subject = subjectsWithBooks[index];
            return _SubjectBooksCard(subject: subject);
          },
        );
      },
    );
  }
}

class _SubjectBooksCard extends StatelessWidget {
  final Subject subject;

  const _SubjectBooksCard({required this.subject});

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
            final status = bookService.getBookStatus(bookId);
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

            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code),
              ),
              title: Text('Book ID: $bookId'),
              subtitle: Text(
                code,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
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
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
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
