import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:file_selector/file_selector.dart';
import '../../services/file_selector_service.dart';
import 'package:flutter/services.dart';
// share_plus not used for direct save; keep dependency available if sharing later

import 'package:provider/provider.dart';

import '../../services/database_service.dart';
import '../../services/book_service.dart';
import '../../services/theme_service.dart';
import '../../services/timetable_service.dart';
import '../../main.dart' show TutorialDialog;
import '../../models/models.dart';
// removed file_utils usage after simplifying import/export to file picker only

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
  String scheduleMode = 'weekly';
  int? customCycleDays; // for multi-day cycles
  int? customNWeeks; // for custom N-week cycles

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  static const MethodChannel _channel = MethodChannel('classflow');

  void _loadSettings() {
    invertWeekParity =
        (DatabaseService.settings['invertWeekParity'] as bool?) ?? false;
    final iso = DatabaseService.settings['week1StartDate'] as String?;
    themeMode = (DatabaseService.settings['themeMode'] as String?) ?? 'system';
    exportPath = DatabaseService.settings['exportPath'] as String?;
    scheduleMode =
        (DatabaseService.settings['scheduleMode'] as String?) ?? 'weekly';
    customCycleDays = DatabaseService.settings['customCycleDays'] as int?;
    customNWeeks = DatabaseService.settings['customNWeeks'] as int?;
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
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'app',
                      label: Text('Use app documents folder (default)'),
                    ),
                    ButtonSegment<String>(
                      value: 'custom',
                      label: Text('Custom folder'),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (sel) =>
                      setStateDialog(() => mode = sel.first),
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
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('No folder selected')),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(ctx).showSnackBar(
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
                    DatabaseService.settings.remove('exportPath');
                    await DatabaseService.save();
                    setState(() => exportPath = null);
                    // ignore: use_build_context_synchronously
                    Navigator.of(ctx).pop(true);
                    return;
                  }

                  final path = controller.text.trim();
                  if (path.isEmpty) {
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Please enter a path')),
                    );
                    return;
                  }

                  try {
                    // If the path looks like a SAF tree URI (content://), store it directly
                    if (path.startsWith('content://')) {
                      DatabaseService.settings['exportPath'] = path;
                      await DatabaseService.save();
                      if (!mounted) return;
                      setState(() => exportPath = path);
                      // ignore: use_build_context_synchronously
                      Navigator.of(ctx).pop(true);
                      return;
                    }

                    final dir = Directory(path);
                    if (!await dir.exists()) {
                      await dir.create(recursive: true);
                    }
                    // try writing a small hidden test file to verify writable
                    final test = File(
                      '${dir.path}${Platform.pathSeparator}.classflow_test',
                    );
                    await test.writeAsString('ok');
                    await test.delete();

                    DatabaseService.settings['exportPath'] = path;
                    await DatabaseService.save();
                    if (!mounted) return;
                    setState(() => exportPath = path);
                    // ignore: use_build_context_synchronously
                    Navigator.of(ctx).pop(true);
                  } catch (e) {
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(ctx).showSnackBar(
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

    if (result == true && mounted) setState(() {});
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
      if (!mounted) return;
      setState(() => week1StartDate = picked);
      DatabaseService.settings['week1StartDate'] = picked.toIso8601String();
      await DatabaseService.save();
    }
  }

  void _setThemeMode(String mode) {
    setState(() => themeMode = mode);
    final themeService = context.read<ThemeService>();
    switch (mode) {
      case 'light':
        themeService.setMode(ThemeMode.light);
        break;
      case 'dark':
        themeService.setMode(ThemeMode.dark);
        break;
      default:
        themeService.setMode(ThemeMode.system);
        break;
    }
  }

  void _resetWeek1Reference() {
    setState(() {
      week1StartDate = null;
      invertWeekParity = false;
      DatabaseService.settings.remove('week1StartDate');
      DatabaseService.settings['invertWeekParity'] = false;
      DatabaseService.save();
    });
  }

  Future<void> _showProgressDialog(String title) async {
    if (!mounted) return;
    showDialog(
      // ignore: use_build_context_synchronously
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
    if (!mounted) return; // before pop
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
    if (!mounted) return; // before snackbar
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated $updated subject mappings')),
    );
    setState(() {});
  }

  Future<void> _repairStatuses() async {
    final bookService = context.read<BookService>();
    await _showProgressDialog('Repairing book statuses...');
    final result = await bookService.repairBookStatuses();
    if (!mounted) return; // before pop
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
    if (!mounted) return; // before snackbar
    // ignore: use_build_context_synchronously
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
    DatabaseService.settings.remove('exportPath');
    await DatabaseService.save();
    setState(() => exportPath = null);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export path reset to app documents folder'),
      ),
    );
  }

  void _setScheduleMode(String mode) {
    setState(() => scheduleMode = mode);
    DatabaseService.settings['scheduleMode'] = mode;
    DatabaseService.save();
  }

  Future<void> _runAllFixes() async {
    final bookService = context.read<BookService>();
    await _showProgressDialog('Running all fixes...');
    final summary = await bookService.runAllRepairs();
    if (!mounted) return; // before pop
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
    if (!mounted) return; // before snackbar
    // ignore: use_build_context_synchronously
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
    DatabaseService.settings['invertWeekParity'] = v;
    DatabaseService.save();
  }

  Future<void> _exportData() async {
    try {
      final Map<String, dynamic> payload = {};

      // Subjects
      payload['subjects'] = DatabaseService.subjects.map((s) {
        return {
          'id': s.id,
          'name': s.name,
          'bookIds': s.bookIds,
          'colorValue': s.colorValue,
        };
      }).toList();

      // Books
      payload['books'] = DatabaseService.books.map((b) {
        return {
          'id': b.id,
          'subjectId': b.subjectId,
          'description': b.description,
          'createdAt': b.createdAt.toIso8601String(),
        };
      }).toList();

      // Lessons
      payload['lessons'] = DatabaseService.lessons.map((l) {
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

      // Settings
      payload['settings'] = Map<String, dynamic>.from(DatabaseService.settings);

      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      final fileName =
          'classflow_export_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';

      // Only use a file picker (or share sheet on iOS)
      final fs = FileSelectorService();
      final saved = await fs.saveFile(
        suggestedName: fileName,
        mimeType: 'application/json',
        bytes: Uint8List.fromList(utf8.encode(jsonStr)),
      );

      if (Platform.isIOS) {
        // iOS uses share sheet; no path to show
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('Export Shared'),
            content: Text('Choose where to save the exported file.'),
          ),
        );
        return;
      }

      if (saved == null) {
        // User canceled
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('Export Canceled'),
            content: Text('No file was saved.'),
          ),
        );
        return;
      }

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Export Saved'),
          content: Text('Saved to:\n${saved.path}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog(
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
    try {
      final fs = FileSelectorService();
      final XFile? picked = await fs.pickSingleFile(
        typeGroups: [
          const XTypeGroup(label: 'json', extensions: ['json']),
        ],
      );

      if (picked == null) {
        // User canceled
        return;
      }

      final content = await picked.readAsString();
      await _processImportedContent(content);
    } catch (e) {
      if (!mounted) return;
      await showDialog(
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

      // Clear existing in-memory data (excluding templates and special lessons)
      DatabaseService.subjects.clear();
      DatabaseService.books.clear();
      DatabaseService.lessons.clear();

      // Restore subjects
      if (payload['subjects'] is List) {
        for (final item in (payload['subjects'] as List)) {
          final s = Subject(
            id: item['id'] as int,
            name: item['name'] as String,
            bookIds: List<int>.from(item['bookIds'] ?? []),
            colorValue: item['colorValue'] as int?,
          );
          DatabaseService.subjects.add(s);
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
          DatabaseService.books.add(b);
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
          DatabaseService.lessons.add(l);
        }
      }

      // Templates and special lessons are no longer imported here

      // Settings
      if (payload['settings'] is Map) {
        DatabaseService.settings
          ..clear()
          ..addAll(Map<String, dynamic>.from(payload['settings'] as Map));
      }

      await DatabaseService.save();

      // Refresh UI
      if (!mounted) return;
      setState(() {});
      if (!mounted) return;
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
      if (!mounted) return;
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
              ListTile(
                title: const Text('Schedule type'),
                subtitle: Text(_scheduleModeLabel(scheduleMode)),
                trailing: DropdownButton<String>(
                  value: scheduleMode,
                  items: const [
                    DropdownMenuItem(
                      value: 'weekly',
                      child: Text('Weekly fixed schedule'),
                    ),
                    DropdownMenuItem(
                      value: 'biweekly_ab',
                      child: Text('Biweekly (A/B week)'),
                    ),
                    DropdownMenuItem(
                      value: 'custom_n_week',
                      child: Text('Custom N-week cycle'),
                    ),
                  ],
                  onChanged: (v) => _setScheduleMode(v ?? 'weekly'),
                ),
              ),
              const SizedBox(height: 8),
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
                          if (!mounted) return; // before pop
                          // ignore: use_build_context_synchronously
                          Navigator.of(context).pop();
                          if (!mounted) return; // before snackbar
                          // ignore: use_build_context_synchronously
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
              ElevatedButton.icon(
                onPressed: () async {
                  // Allow user to re-show the onboarding/tutorial dialog.
                  DatabaseService.settings['hasSeenTutorial'] = false;
                  await DatabaseService.save();
                  // Immediately show the tutorial now.
                  if (!mounted) return; // before accessing context
                  // ignore: use_build_context_synchronously
                  final timetable = context.read<TimetableService>();
                  final hasLessons = timetable.lessons.isNotEmpty;
                  final usesWeekNumbers = timetable.lessons.any(
                    (l) => l.weekNumber != 0,
                  );
                  if (!mounted) return; // before showDialog
                  // ignore: use_build_context_synchronously
                  await showDialog<void>(
                    // ignore: use_build_context_synchronously
                    context: context,
                    barrierDismissible: true,
                    builder: (context) {
                      return TutorialDialog(
                        hasLessons: hasLessons,
                        usesWeekNumbers: usesWeekNumbers,
                      );
                    },
                  );
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('Show tutorial'),
              ),
              const SizedBox(height: 24),
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

  String _scheduleModeLabel(String mode) {
    switch (mode) {
      case 'biweekly_ab':
        return 'Biweekly (A/B week) schedule';
      case 'custom_n_week':
        return 'Custom N-week cycle';
      case 'weekly':
      default:
        return 'Weekly fixed schedule';
    }
  }
}
