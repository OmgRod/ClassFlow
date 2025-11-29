import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';

class SubjectFormScreen extends StatefulWidget {
  final Subject? subject;

  const SubjectFormScreen({super.key, this.subject});

  @override
  State<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends State<SubjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late List<int> _bookIds;
  late Color _selectedColor;
  bool _isLoading = false;

  bool get isEditing => widget.subject != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name ?? '');
    _bookIds = List.from(widget.subject?.bookIds ?? []);
    _selectedColor = widget.subject?.colorValue != null
        ? Color(widget.subject!.colorValue!)
        : AppColors.subjectColors[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Subject' : 'Add Subject'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                hintText: 'e.g., MATHS, ENGLISH, PHYSICS',
                helperText: 'Will be converted to UPPERCASE with no spaces',
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a subject name';
                }
                return null;
              },
              onChanged: (value) {
                // Preview the formatted name
                setState(() {});
              },
            ),
            if (_nameController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Preview: ${Subject.formatName(_nameController.text)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Color picker
            Text(
              'Subject Color',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _ColorPickerRow(
              selectedColor: _selectedColor,
              onColorSelected: (color) {
                setState(() => _selectedColor = color);
              },
              onCustomColor: _showColorPicker,
            ),
            const SizedBox(height: 24),

            // Book IDs section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Book IDs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _addBookId,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_bookIds.isEmpty)
              Card(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).cardColor
                    : Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No books yet. Tap + to add a book ID.',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade300
                          : Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ..._bookIds.asMap().entries.map((entry) {
                final index = entry.key;
                final bookId = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _selectedColor.withValues(alpha: 0.2),
                      child: Text(
                        '$bookId',
                        style: TextStyle(
                          color: _selectedColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text('Book ID: $bookId'),
                    subtitle: _nameController.text.isNotEmpty
                        ? Text(
                            'Code: ${widget.subject?.id ?? context.read<SubjectService>().nextId}-$bookId-${Subject.formatName(_nameController.text)}',
                            style: const TextStyle(fontFamily: 'monospace'),
                          )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.red,
                      onPressed: () => _removeBookId(index),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Update Subject' : 'Add Subject'),
            ),
          ],
        ),
      ),
    );
  }

  void _addBookId() {
    final nextBookId = _bookIds.isEmpty
        ? 1
        : _bookIds.reduce((a, b) => a > b ? a : b) + 1;

    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: '$nextBookId');
        return AlertDialog(
          title: const Text('Add Book ID'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Book ID',
              hintText: 'Enter a number',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final id = int.tryParse(controller.text);
                if (id != null && !_bookIds.contains(id)) {
                  setState(() => _bookIds.add(id));
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeBookId(int index) {
    setState(() => _bookIds.removeAt(index));
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        Color pickerColor = _selectedColor;
        return AlertDialog(
          title: const Text('Pick a Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) => pickerColor = color,
              enableAlpha: false,
              displayThumbColor: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() => _selectedColor = pickerColor);
                Navigator.pop(context);
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final subjectService = context.read<SubjectService>();
      final bookService = context.read<BookService>();
      final formattedName = Subject.formatName(_nameController.text);

      if (isEditing) {
        final updatedSubject = widget.subject!.copyWith(
          name: formattedName,
          bookIds: _bookIds,
          colorValue: _selectedColor.toARGB32(),
        );
        await subjectService.updateSubject(updatedSubject);
      } else {
        final subject = await subjectService.addSubject(
          name: formattedName,
          bookIds: _bookIds,
          colorValue: _selectedColor.toARGB32(),
        );

        // Create book entries for each book ID
        for (final bookId in _bookIds) {
          // Check if book already exists
          if (bookService.getBookById(bookId) == null) {
            await bookService.addBook(subjectId: subject.id, bookId: bookId);
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Subject updated' : 'Subject added'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
          'Are you sure you want to delete "${widget.subject!.name}"?\n\n'
          'This will also delete all associated books and lessons.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<SubjectService>().deleteSubject(widget.subject!.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close form
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${widget.subject!.name} deleted')),
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

class _ColorPickerRow extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback onCustomColor;

  const _ColorPickerRow({
    required this.selectedColor,
    required this.onColorSelected,
    required this.onCustomColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...AppColors.subjectColors.map((color) {
          final isSelected = color.toARGB32() == selectedColor.toARGB32();
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.black, width: 3)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        }),
        // Custom color button
        GestureDetector(
          onTap: onCustomColor,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey, width: 2),
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.green, Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.colorize, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}
