import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import 'lesson_form_screen.dart';
import '../scanner/scanner_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TimetableService, SubjectService>(
      builder: (context, timetableService, subjectService, child) {
        return Column(
          children: [
            // Calendar
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
              ),
              eventLoader: (day) {
                return timetableService.getLessonsForCalendarDate(day);
              },
            ),
            const Divider(),

            // Lessons for selected day
            Expanded(
              child: _buildLessonsList(timetableService, subjectService),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLessonsList(
    TimetableService timetableService,
    SubjectService subjectService,
  ) {
    if (_selectedDay == null) {
      return const Center(child: Text('Select a day'));
    }

    final dayOfWeek = _selectedDay!.weekday;
    final lessons = timetableService.getLessonsForCalendarDate(_selectedDay!);
    final specialLessons = timetableService.getSpecialLessonsForDate(
      _selectedDay!,
    );

    if (lessons.isEmpty) {
      return _buildEmptyDayView(dayOfWeek);
    }

    return Stack(
      children: [
        if (specialLessons.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Special lessons for this date',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...specialLessons.map((s) {
                  final subject = subjectService.getSubjectById(s.subjectId);
                  return Card(
                    color: Colors.yellow.shade50,
                    child: ListTile(
                      title: Text(subject?.name ?? 'Unknown Subject'),
                      subtitle: Text(
                        '${s.startHour.toString().padLeft(2, '0')}:${s.startMinute.toString().padLeft(2, '0')} - ${s.endHour.toString().padLeft(2, '0')}:${s.endMinute.toString().padLeft(2, '0')}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            timetableService.deleteSpecialLesson(s.id),
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lessons.length,
          itemBuilder: (context, index) {
            final lesson = lessons[index];
            final subject = subjectService.getSubjectById(lesson.subjectId);
            final conflicts = timetableService.getConflicts(lesson);

            return _LessonCard(
              lesson: lesson,
              subject: subject,
              hasConflict: conflicts.isNotEmpty,
              onTap: () => _showLessonDetails(lesson, subject),
              onEdit: () => _editLesson(lesson),
              onDelete: () => _confirmDeleteLesson(lesson, timetableService),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'scan_day',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScannerScreen()),
                  );
                },
                child: const Icon(Icons.qr_code_scanner),
                tooltip: 'Scan / Manage books for this day',
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'regular',
                onPressed: () => _addLesson(dayOfWeek),
                child: const Icon(Icons.add),
                tooltip: 'Add Lesson',
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'special',
                onPressed: () => _addSpecialLesson(_selectedDay!),
                child: const Icon(Icons.star),
                tooltip: 'Add Special Lesson',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDayView(int dayOfWeek) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No lessons on ${AppConstants.getDayName(dayOfWeek)}',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addLesson(dayOfWeek),
            icon: const Icon(Icons.add),
            label: const Text('Add Lesson'),
          ),
        ],
      ),
    );
  }

  void _addLesson(int dayOfWeek) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LessonFormScreen(dayOfWeek: dayOfWeek, weekNumber: 0),
      ),
    );
  }

  void _editLesson(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LessonFormScreen(lesson: lesson)),
    );
  }

  void _showLessonDetails(Lesson lesson, Subject? subject) {
    final color = subject?.colorValue != null
        ? Color(subject!.colorValue!)
        : (subject != null
              ? AppColors.getDefaultSubjectColor(subject.id)
              : Colors.grey);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                      subject?.name.isNotEmpty == true ? subject!.name[0] : '?',
                      style: TextStyle(
                        fontSize: 24,
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
                        subject?.name ?? 'Unknown Subject',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${lesson.formattedStartTime} - ${lesson.formattedEndTime}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.calendar_today, lesson.dayName),
            _buildDetailRow(
              Icons.timer,
              TimeUtils.formatDuration(lesson.durationMinutes),
            ),
            _buildDetailRow(Icons.repeat, _getRecurrenceText(lesson)),
            if (lesson.weekNumber > 0)
              _buildDetailRow(Icons.view_week, 'Week ${lesson.weekNumber}'),
            if (lesson.notes != null && lesson.notes!.isNotEmpty)
              _buildDetailRow(Icons.note, lesson.notes!),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _editLesson(lesson);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDeleteLesson(
                      lesson,
                      context.read<TimetableService>(),
                    );
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  String _getRecurrenceText(Lesson lesson) {
    switch (lesson.recurrenceType) {
      case RecurrenceType.everyWeek:
        return 'Every week';
      case RecurrenceType.everyTwoWeeks:
        return 'Every 2 weeks';
      case RecurrenceType.custom:
        return 'Every ${lesson.customIntervalWeeks ?? 1} weeks';
    }
  }

  void _confirmDeleteLesson(Lesson lesson, TimetableService timetableService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: const Text('Are you sure you want to delete this lesson?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              timetableService.deleteLesson(lesson.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Lesson deleted')));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addSpecialLesson(DateTime forDate) {
    final timetableService = context.read<TimetableService>();
    final subjectService = context.read<SubjectService>();
    int selectedSubjectId = subjectService.subjects.isNotEmpty
        ? subjectService.subjects.first.id
        : 0;
    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Special Lesson'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: selectedSubjectId,
                items: subjectService.subjects
                    .map(
                      (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => selectedSubjectId = v ?? selectedSubjectId),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: start,
                      );
                      if (t != null) setState(() => start = t);
                    },
                    child: Text('Start: ${start.format(context)}'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: end,
                      );
                      if (t != null) setState(() => end = t);
                    },
                    child: Text('End: ${end.format(context)}'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final id = DateTime.now().microsecondsSinceEpoch.toString();
                timetableService.addSpecialLesson(
                  id: id,
                  date: DateTime(forDate.year, forDate.month, forDate.day),
                  subjectId: selectedSubjectId,
                  startHour: start.hour,
                  startMinute: start.minute,
                  endHour: end.hour,
                  endMinute: end.minute,
                );
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final Subject? subject;
  final bool hasConflict;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LessonCard({
    required this.lesson,
    required this.subject,
    required this.hasConflict,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = subject?.colorValue != null
        ? Color(subject!.colorValue!)
        : (subject != null
              ? AppColors.getDefaultSubjectColor(subject!.id)
              : Colors.grey);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasConflict
            ? const BorderSide(color: Colors.orange, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Time column
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      lesson.formattedStartTime,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Container(
                      height: 20,
                      width: 1,
                      color: color.withOpacity(0.3),
                    ),
                    Text(
                      lesson.formattedEndTime,
                      style: TextStyle(color: color),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Subject color indicator
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Subject info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subject?.name ?? 'Unknown Subject',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (hasConflict)
                          Tooltip(
                            message: 'Time conflict with another lesson',
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange.shade700,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      TimeUtils.formatDuration(lesson.durationMinutes),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    if (lesson.weekNumber > 0)
                      Text(
                        'Week ${lesson.weekNumber}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
