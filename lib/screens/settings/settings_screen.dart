import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:convert';
// share_plus not used for direct save; keep dependency available if sharing later

import 'package:provider/provider.dart';

import '../../services/database_service.dart';
import '../../services/book_service.dart';
import '../../models/models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool invertWeekParity = false;
  DateTime? week1StartDate;
  String themeMode = 'system'; // 'system' | 'light' | 'dark'
  String? exportPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  static const MethodChannel _channel = MethodChannel('detention_safe');

  void _loadSettings() {
    invertWeekParity =
        DatabaseService.settingsBox.get('invertWeekParity', defaultValue: false)
            as bool;
    final iso = DatabaseService.settingsBox.get('week1StartDate') as String?;
    themeMode =
        DatabaseService.settingsBox.get('themeMode', defaultValue: 'system')
            as String;
    exportPath = DatabaseService.settingsBox.get('exportPath') as String?;
    if (iso != null) week1StartDate = DateTime.tryParse(iso);
    setState(() {});
  }

  Future<void> _changeExportPath() async {
    String mode = exportPath == null ? 'app' : 'custom';
    final controller = TextEditingController(text: exportPath ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setStateDialog) {
          return AlertDialog(
            title: const Text('Export Folder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  value: 'app',
                  groupValue: mode,
                  title: const Text('Use app documents folder (default)'),
                  onChanged: (v) => setStateDialog(() => mode = v ?? 'app'),
                ),
                RadioListTile<String>(
                  value: 'custom',
                  groupValue: mode,
                  title: const Text('Custom folder'),
                  onChanged: (v) => setStateDialog(() => mode = v ?? 'custom'),
                ),
                if (mode == 'custom')
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Folder path',
                      hintText:
                          r'C:\Users\you\Downloads or /storage/emulated/0/Download',
                    ),
                  ),
                const SizedBox(height: 8),
                if (Platform.isAndroid)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Choose folder (Android SAF)'),
                    onPressed: () async {
                      try {
                        final uri = await _channel.invokeMethod<String>(
                          'pickDirectory',
                        );
                        if (uri != null) {
                          // Store the SAF tree URI as exportPath
                          controller.text = uri;
                          setStateDialog(() => mode = 'custom');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No folder selected')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Folder picker failed: $e')),
                        );
                      }
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (mode == 'app') {
                    DatabaseService.settingsBox.delete('exportPath');
                    setState(() => exportPath = null);
                    Navigator.of(ctx).pop(true);
                    return;
                  }

                  final path = controller.text.trim();
                  if (path.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a path')),
                    );
                    return;
                  }

                  try {
                    // If the path looks like a SAF tree URI (content://), store it directly
                    if (path.startsWith('content://')) {
                      DatabaseService.settingsBox.put('exportPath', path);
                      setState(() => exportPath = path);
                      Navigator.of(ctx).pop(true);
                      return;
                    }

                    final dir = Directory(path);
                    if (!await dir.exists()) {
                      await dir.create(recursive: true);
                    }
                    // try writing a small hidden test file to verify writable
                    final test = File(
                      '${dir.path}${Platform.pathSeparator}.detention_safe_test',
                    );
                    await test.writeAsString('ok');
                    await test.delete();

                    DatabaseService.settingsBox.put('exportPath', path);
                    setState(() => exportPath = path);
                    Navigator.of(ctx).pop(true);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to set folder: $e')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) setState(() {});
  }

  Future<void> _pickWeek1Date() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: week1StartDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => week1StartDate = picked);
      DatabaseService.settingsBox.put(
        'week1StartDate',
        picked.toIso8601String(),
      );
    }
  }

  void _setThemeMode(String mode) {
    setState(() => themeMode = mode);
    DatabaseService.settingsBox.put('themeMode', mode);
  }

  void _resetWeek1Reference() {
    setState(() {
      week1StartDate = null;
      invertWeekParity = false;
      DatabaseService.settingsBox.delete('week1StartDate');
      DatabaseService.settingsBox.put('invertWeekParity', false);
    });
  }

  Future<void> _showProgressDialog(String title) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
      ),
    );
  }

  Future<void> _repairMappings() async {
    final bookService = context.read<BookService>();
    await _showProgressDialog('Repairing subject ↔ book mappings...');
    final updated = await bookService.repairSubjectBookMappings();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated $updated subject mappings')),
    );
    setState(() {});
  }

  Future<void> _repairStatuses() async {
    final bookService = context.read<BookService>();
    await _showProgressDialog('Repairing book statuses...');
    final result = await bookService.repairBookStatuses();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Removed ${result['removed']} invalid statuses, added ${result['added']} defaults',
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _resetExportPathQuick() async {
    DatabaseService.settingsBox.delete('exportPath');
    setState(() => exportPath = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export path reset to app documents folder'),
      ),
    );
  }

  Future<void> _runAllFixes() async {
    final bookService = context.read<BookService>();
    await _showProgressDialog('Running all fixes...');
    final summary = await bookService.runAllRepairs();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Updated ${summary['updatedSubjects']} subjects; removed ${summary['statusesRemoved']} statuses; added ${summary['statusesAdded']}',
        ),
      ),
    );
    setState(() {});
  }

  void _toggleInvert(bool v) {
    setState(() => invertWeekParity = v);
    DatabaseService.settingsBox.put('invertWeekParity', v);
  }

  Future<void> _exportData() async {
    try {
      final Map<String, dynamic> payload = {};

      // Subjects
      payload['subjects'] = DatabaseService.subjectsBox.values.map((s) {
        return {
          'id': s.id,
          'name': s.name,
          'bookIds': s.bookIds,
          'colorValue': s.colorValue,
        };
      }).toList();

      // Books
      payload['books'] = DatabaseService.booksBox.values.map((b) {
        return {
          'id': b.id,
          'subjectId': b.subjectId,
          'description': b.description,
          'createdAt': b.createdAt.toIso8601String(),
        };
      }).toList();

      // Lessons
      payload['lessons'] = DatabaseService.lessonsBox.values.map((l) {
        return {
          'id': l.id,
          'subjectId': l.subjectId,
          'dayOfWeek': l.dayOfWeek,
          'startHour': l.startHour,
          'startMinute': l.startMinute,
          'endHour': l.endHour,
          'endMinute': l.endMinute,
          'recurrenceType': l.recurrenceType.index,
          'customIntervalWeeks': l.customIntervalWeeks,
          'startDate': l.startDate?.toIso8601String(),
          'templateId': l.templateId,
          'notes': l.notes,
          'weekNumber': l.weekNumber,
        };
      }).toList();

      // Templates
      payload['templates'] = DatabaseService.templatesBox.values.map((t) {
        return {
          'id': t.id,
          'name': t.name,
          'startHour': t.startHour,
          'startMinute': t.startMinute,
          'endHour': t.endHour,
          'endMinute': t.endMinute,
          'description': t.description,
        };
      }).toList();

      // Special lessons
      final specialBox = DatabaseService.specialLessonsBox;
      payload['special_lessons'] = specialBox.values
          .whereType<SpecialLesson>()
          .map((s) {
            return {
              'id': s.id,
              'date': s.date.toIso8601String(),
              'subjectId': s.subjectId,
              'startHour': s.startHour,
              'startMinute': s.startMinute,
              'endHour': s.endHour,
              'endMinute': s.endMinute,
              'originalLessonId': s.originalLessonId,
              'notes': s.notes,
            };
          })
          .toList();

      // Settings
      payload['settings'] = Map.fromEntries(
        DatabaseService.settingsBox.keys.map(
          (k) => MapEntry(k.toString(), DatabaseService.settingsBox.get(k)),
        ),
      );

      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      String? custom = DatabaseService.settingsBox.get('exportPath') as String?;
      Directory dir;
      if (custom != null && custom.isNotEmpty) {
        dir = Directory(custom);
        if (!await dir.exists()) await dir.create(recursive: true);
      } else {
        // If no custom path is set, let Android users choose where to save (SAF) or use Downloads.
        try {
          if (Platform.isAndroid) {
            // Ask the user whether they want to choose a folder or save to Downloads
            final choice = await showDialog<String?>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Export Destination'),
                content: const Text(
                  'Where would you like to save the export file?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop('downloads'),
                    child: const Text('Downloads (recommended)'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop('choose'),
                    child: const Text('Choose folder'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            );

            if (choice == 'choose') {
              try {
                final uri = await _channel.invokeMethod<String>(
                  'pickDirectory',
                );
                if (uri != null && uri.isNotEmpty) {
                  // store the SAF tree URI for future exports and use it for this export
                  DatabaseService.settingsBox.put('exportPath', uri);
                  custom = uri;
                  // use app documents as a local fallback path variable (we won't write to it when custom is a SAF URI)
                  dir = await getApplicationDocumentsDirectory();
                } else {
                  // user cancelled picker, fall back to Downloads
                  final dirs = await getExternalStorageDirectories(
                    type: StorageDirectory.downloads,
                  );
                  if (dirs != null && dirs.isNotEmpty) {
                    dir = dirs.first;
                  } else {
                    dir = await getApplicationDocumentsDirectory();
                  }
                }
              } catch (e) {
                // If SAF picker fails, fallback to Downloads
                final dirs = await getExternalStorageDirectories(
                  type: StorageDirectory.downloads,
                );
                if (dirs != null && dirs.isNotEmpty) {
                  dir = dirs.first;
                } else {
                  dir = await getApplicationDocumentsDirectory();
                }
              }
            } else if (choice == 'downloads') {
              final dirs = await getExternalStorageDirectories(
                type: StorageDirectory.downloads,
              );
              if (dirs != null && dirs.isNotEmpty) {
                dir = dirs.first;
              } else {
                dir = await getApplicationDocumentsDirectory();
              }
            } else {
              // cancelled - use app documents
              dir = await getApplicationDocumentsDirectory();
            }
          } else {
            dir = await getApplicationDocumentsDirectory();
          }
          if (!await dir.exists()) await dir.create(recursive: true);
        } catch (e) {
          // Fallback to app documents if external access fails
          dir = await getApplicationDocumentsDirectory();
          if (!await dir.exists()) await dir.create(recursive: true);
        }
      }

      final fileName =
          'detention_safe_export_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';
      // If custom path is a SAF tree URI (content://...), try saving via platform channel
      try {
        if (custom != null && custom.startsWith('content://')) {
          final bytes = Uint8List.fromList(utf8.encode(jsonStr));
          final ok = await _channel.invokeMethod<bool>('saveFileToUri', {
            'treeUri': custom,
            'filename': fileName,
            'bytes': bytes,
          });
          if (ok == true) {
            await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Export Saved'),
                content: const Text(
                  'Export saved to selected folder (via SAF).',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            return;
          }
        }

        // Otherwise try MediaStore Downloads first (better visibility on many Android devices)
        if (Platform.isAndroid) {
          final bytes = Uint8List.fromList(utf8.encode(jsonStr));
          final ok = await _channel.invokeMethod<bool>('saveBytesToDownloads', {
            'filename': fileName,
            'mime': 'application/json',
            'bytes': bytes,
          });
          if (ok == true) {
            await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Export Saved'),
                content: Text('Export saved to Downloads as $fileName'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            return;
          }
        }

        // Fallback: write to chosen directory or app documents
        final file = File('${dir.path}${Platform.pathSeparator}$fileName');
        await file.writeAsString(jsonStr);

        // Saved to file; inform the user of location
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Export Saved'),
            content: Text('Export saved to:\n${file.path}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        // If platform channel failed or MediaStore failed, show a robust error message
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Export Failed'),
            content: Text('Failed to save export: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Export Failed'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _importData() async {
    // First try the platform-native file selector (Android SAF / iOS document picker / desktop file chooser)
    try {
      final XFile? picked = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(label: 'json', extensions: ['json']),
        ],
      );

      if (picked != null) {
        final content = await picked.readAsString();
        await _processImportedContent(content);
        return;
      }
    } catch (e) {
      // If the file selector fails or is unavailable on a platform, fall back to documents-folder listing below.
      debugPrint('file_selector not available or failed: $e');
    }

    // Look for exported JSON files in the app documents directory
    final dir = await getApplicationDocumentsDirectory();
    final files = Directory(dir.path)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.json'))
        .toList();

    if (files.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No import files found'),
          content: Text(
            'No JSON files were found in the app documents folder:\n${dir.path}\n\nPlease place your export JSON file there and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Let user choose one of the discovered JSON files
    final selected = await showDialog<File?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select import file'),
        children: files.map((f) {
          final name = f.uri.pathSegments.last;
          return SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(f),
            child: Text(name),
          );
        }).toList(),
      ),
    );

    if (selected == null) return;

    final content = await selected.readAsString();

    // Warn user about overwrite
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'Importing will overwrite the app data. Please back up current data first. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final Map<String, dynamic> payload =
          json.decode(content) as Map<String, dynamic>;

      // Clear existing boxes
      await DatabaseService.subjectsBox.clear();
      await DatabaseService.booksBox.clear();
      await DatabaseService.lessonsBox.clear();
      await DatabaseService.templatesBox.clear();
      await DatabaseService.specialLessonsBox.clear();

      // Restore subjects
      if (payload['subjects'] is List) {
        for (final item in (payload['subjects'] as List)) {
          final s = Subject(
            id: item['id'] as int,
            name: item['name'] as String,
            bookIds: List<int>.from(item['bookIds'] ?? []),
            colorValue: item['colorValue'] as int?,
          );
          await DatabaseService.subjectsBox.put(s.id, s);
        }
      }

      // Books
      if (payload['books'] is List) {
        for (final item in (payload['books'] as List)) {
          final b = Book(
            id: item['id'] as int,
            subjectId: item['subjectId'] as int,
            description: item['description'] as String?,
            createdAt: item['createdAt'] != null
                ? DateTime.parse(item['createdAt'] as String)
                : DateTime.now(),
          );
          await DatabaseService.booksBox.put(b.id, b);
        }
      }

      // Templates
      if (payload['templates'] is List) {
        for (final item in (payload['templates'] as List)) {
          final t = LessonTemplate(
            id: item['id'] as String,
            name: item['name'] as String,
            startHour: item['startHour'] as int,
            startMinute: item['startMinute'] as int,
            endHour: item['endHour'] as int,
            endMinute: item['endMinute'] as int,
            description: item['description'] as String?,
          );
          await DatabaseService.templatesBox.put(t.id, t);
        }
      }

      // Lessons
      if (payload['lessons'] is List) {
        for (final item in (payload['lessons'] as List)) {
          final l = Lesson(
            id: item['id'] as String,
            subjectId: item['subjectId'] as int,
            dayOfWeek: item['dayOfWeek'] as int,
            startHour: item['startHour'] as int,
            startMinute: item['startMinute'] as int,
            endHour: item['endHour'] as int,
            endMinute: item['endMinute'] as int,
            recurrenceType:
                RecurrenceType.values[item['recurrenceType'] as int],
            customIntervalWeeks: item['customIntervalWeeks'] as int?,
            startDate: item['startDate'] != null
                ? DateTime.parse(item['startDate'] as String)
                : null,
            templateId: item['templateId'] as String?,
            notes: item['notes'] as String?,
            weekNumber: item['weekNumber'] as int? ?? 0,
          );
          await DatabaseService.lessonsBox.put(l.id, l);
        }
      }

      // Special lessons
      if (payload['special_lessons'] is List) {
        final box = DatabaseService.specialLessonsBox;
        for (final item in (payload['special_lessons'] as List)) {
          final s = SpecialLesson(
            id: item['id'] as String,
            date: DateTime.parse(item['date'] as String),
            subjectId: item['subjectId'] as int,
            startHour: item['startHour'] as int,
            startMinute: item['startMinute'] as int,
            endHour: item['endHour'] as int,
            endMinute: item['endMinute'] as int,
            originalLessonId: item['originalLessonId'] as String?,
            notes: item['notes'] as String?,
          );
          await box.put(s.id, s);
        }
      }

      // Settings
      if (payload['settings'] is Map) {
        for (final entry in (payload['settings'] as Map).entries) {
          DatabaseService.settingsBox.put(entry.key.toString(), entry.value);
        }
      }

      // Refresh UI
      setState(() {});
      // Notify DatabaseService listeners indirectly via TimetableService/others when user navigates
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Import Successful'),
          content: const Text('Data imported successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Import Failed'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _processImportedContent(String content) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'Importing will overwrite the app data. Please back up current data first. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final Map<String, dynamic> payload =
          json.decode(content) as Map<String, dynamic>;

      // Clear existing boxes
      await DatabaseService.subjectsBox.clear();
      await DatabaseService.booksBox.clear();
      await DatabaseService.lessonsBox.clear();
      await DatabaseService.templatesBox.clear();
      await DatabaseService.specialLessonsBox.clear();

      // Restore subjects
      if (payload['subjects'] is List) {
        for (final item in (payload['subjects'] as List)) {
          final s = Subject(
            id: item['id'] as int,
            name: item['name'] as String,
            bookIds: List<int>.from(item['bookIds'] ?? []),
            colorValue: item['colorValue'] as int?,
          );
          await DatabaseService.subjectsBox.put(s.id, s);
        }
      }

      // Books
      if (payload['books'] is List) {
        for (final item in (payload['books'] as List)) {
          final b = Book(
            id: item['id'] as int,
            subjectId: item['subjectId'] as int,
            description: item['description'] as String?,
            createdAt: item['createdAt'] != null
                ? DateTime.parse(item['createdAt'] as String)
                : DateTime.now(),
          );
          await DatabaseService.booksBox.put(b.id, b);
        }
      }

      // Templates
      if (payload['templates'] is List) {
        for (final item in (payload['templates'] as List)) {
          final t = LessonTemplate(
            id: item['id'] as String,
            name: item['name'] as String,
            startHour: item['startHour'] as int,
            startMinute: item['startMinute'] as int,
            endHour: item['endHour'] as int,
            endMinute: item['endMinute'] as int,
            description: item['description'] as String?,
          );
          await DatabaseService.templatesBox.put(t.id, t);
        }
      }

      // Lessons
      if (payload['lessons'] is List) {
        for (final item in (payload['lessons'] as List)) {
          final l = Lesson(
            id: item['id'] as String,
            subjectId: item['subjectId'] as int,
            dayOfWeek: item['dayOfWeek'] as int,
            startHour: item['startHour'] as int,
            startMinute: item['startMinute'] as int,
            endHour: item['endHour'] as int,
            endMinute: item['endMinute'] as int,
            recurrenceType:
                RecurrenceType.values[item['recurrenceType'] as int],
            customIntervalWeeks: item['customIntervalWeeks'] as int?,
            startDate: item['startDate'] != null
                ? DateTime.parse(item['startDate'] as String)
                : null,
            templateId: item['templateId'] as String?,
            notes: item['notes'] as String?,
            weekNumber: item['weekNumber'] as int? ?? 0,
          );
          await DatabaseService.lessonsBox.put(l.id, l);
        }
      }

      // Special lessons
      if (payload['special_lessons'] is List) {
        final box = DatabaseService.specialLessonsBox;
        for (final item in (payload['special_lessons'] as List)) {
          final s = SpecialLesson(
            id: item['id'] as String,
            date: DateTime.parse(item['date'] as String),
            subjectId: item['subjectId'] as int,
            startHour: item['startHour'] as int,
            startMinute: item['startMinute'] as int,
            endHour: item['endHour'] as int,
            endMinute: item['endMinute'] as int,
            originalLessonId: item['originalLessonId'] as String?,
            notes: item['notes'] as String?,
          );
          await box.put(s.id, s);
        }
      }

      // Settings
      if (payload['settings'] is Map) {
        for (final entry in (payload['settings'] as Map).entries) {
          DatabaseService.settingsBox.put(entry.key.toString(), entry.value);
        }
      }

      // Refresh UI
      setState(() {});
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Import Successful'),
          content: const Text('Data imported successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Import Failed'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                value: invertWeekParity,
                onChanged: _toggleInvert,
                title: const Text('Invert Week 1 / Week 2'),
                subtitle: const Text(
                  'Flip the parity used for bi-weekly lessons',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Reference Week 1 Date'),
                subtitle: Text(
                  week1StartDate != null
                      ? DateFormat.yMMMMd().format(week1StartDate!)
                      : 'Not set',
                ),
                trailing: TextButton(
                  onPressed: _pickWeek1Date,
                  child: const Text('Set Date'),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(
                  themeMode[0].toUpperCase() + themeMode.substring(1),
                ),
                trailing: DropdownButton<String>(
                  value: themeMode,
                  items: const [
                    DropdownMenuItem(value: 'system', child: Text('System')),
                    DropdownMenuItem(value: 'light', child: Text('Light')),
                    DropdownMenuItem(value: 'dark', child: Text('Dark')),
                  ],
                  onChanged: (v) => _setThemeMode(v ?? 'system'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportData,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Export Data'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _importData,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Import Data'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Export Folder'),
                subtitle: Text(
                  exportPath == null || exportPath!.isEmpty
                      ? 'App documents folder (default)'
                      : exportPath!,
                ),
                trailing: TextButton(
                  onPressed: _changeExportPath,
                  child: const Text('Change'),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _resetWeek1Reference,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Week1 Reference'),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fixes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Run automated repairs for common data issues.',
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _repairMappings,
                        icon: const Icon(Icons.sync_alt),
                        label: const Text('Repair Subject ↔ Book mappings'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _repairStatuses,
                        icon: const Icon(Icons.report_problem),
                        label: const Text('Repair Book Statuses'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final bookService = context.read<BookService>();
                          await _showProgressDialog(
                            'Recreating missing book records...',
                          );
                          final created = await bookService
                              .recreateMissingBooksFromSubjects();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Recreated $created missing book records',
                              ),
                            ),
                          );
                          setState(() {});
                        },
                        icon: const Icon(Icons.restore_page),
                        label: const Text('Recreate missing Book records'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _resetExportPathQuick,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Reset Export Path to default'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _runAllFixes,
                        icon: const Icon(Icons.build),
                        label: const Text('Run All Fixes'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Notes: If a lesson has its own start date that will be used before this global setting.',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
