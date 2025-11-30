import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Screen for exporting timetable in various formats
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isExporting = false;

  Future<void> _exportCSV() async {
    setState(() => _isExporting = true);

    try {
      final timetableService = context.read<TimetableService>();
      final subjectService = context.read<SubjectService>();

      final lessons = timetableService.lessons;
      final subjectNames = <int, String>{};

      for (final lesson in lessons) {
        final subject = subjectService.getSubjectById(lesson.subjectId);
        if (subject != null) {
          subjectNames[lesson.subjectId] = subject.name;
        }
      }

      final csvContent = ExportService.exportToCSV(
        lessons: lessons,
        subjectNames: subjectNames,
      );

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/classflow_timetable.csv');
      await file.writeAsString(csvContent);

      // Share file
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'ClassFlow Timetable Export');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timetable exported to CSV')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportICal() async {
    setState(() => _isExporting = true);

    try {
      final timetableService = context.read<TimetableService>();
      final subjectService = context.read<SubjectService>();

      final lessons = timetableService.lessons;
      final subjectNames = <int, String>{};

      for (final lesson in lessons) {
        final subject = subjectService.getSubjectById(lesson.subjectId);
        if (subject != null) {
          subjectNames[lesson.subjectId] = subject.name;
        }
      }

      // Use next Monday as start date
      final now = DateTime.now();
      final daysUntilMonday = (8 - now.weekday) % 7;
      final startDate = now.add(
        Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday),
      );

      final icalContent = ExportService.exportToICal(
        lessons: lessons,
        subjectNames: subjectNames,
        startDate: startDate,
      );

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/classflow_timetable.ics');
      await file.writeAsString(icalContent);

      // Share file
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'ClassFlow Timetable Calendar');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timetable exported to iCal')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Timetable')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose Export Format',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Export your timetable to share or import into other apps',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // CSV Export
          Card(
            child: ListTile(
              leading: const Icon(Icons.table_chart, size: 32),
              title: const Text('CSV (Spreadsheet)'),
              subtitle: const Text('Import into Excel, Google Sheets, etc.'),
              trailing: _isExporting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward),
              onTap: _isExporting ? null : _exportCSV,
            ),
          ),
          const SizedBox(height: 12),

          // iCal Export
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today, size: 32),
              title: const Text('iCal (Calendar)'),
              subtitle: const Text(
                'Import into Google Calendar, Apple Calendar, etc.',
              ),
              trailing: _isExporting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward),
              onTap: _isExporting ? null : _exportICal,
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Export info
          InfoCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About Exports',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CSV files can be opened in any spreadsheet app. '
                        'iCal files will create recurring events for the next 16 weeks (one semester).',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
