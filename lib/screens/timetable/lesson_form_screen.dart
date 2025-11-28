import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class LessonFormScreen extends StatefulWidget {
  final Lesson? lesson;
  final int? dayOfWeek;
  final int? weekNumber;

  const LessonFormScreen({
    super.key,
    this.lesson,
    this.dayOfWeek,
    this.weekNumber,
  });

  @override
  State<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends State<LessonFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late int _selectedSubjectId;
  late int _selectedDayOfWeek;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late RecurrenceType _recurrenceType;
  late int _customInterval;
  late int _weekNumber;
  late TextEditingController _notesController;

  bool _isLoading = false;

  bool get isEditing => widget.lesson != null;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      final lesson = widget.lesson!;
      _selectedSubjectId = lesson.subjectId;
      _selectedDayOfWeek = lesson.dayOfWeek;
      _startTime = TimeOfDay(
        hour: lesson.startHour,
        minute: lesson.startMinute,
      );
      _endTime = TimeOfDay(hour: lesson.endHour, minute: lesson.endMinute);
      _recurrenceType = lesson.recurrenceType;
      _customInterval = lesson.customIntervalWeeks ?? 1;
      _weekNumber = lesson.weekNumber;
      _notesController = TextEditingController(text: lesson.notes ?? '');
    } else {
      _selectedSubjectId = -1; // Will be set when subjects are loaded
      _selectedDayOfWeek = widget.dayOfWeek ?? 1;
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 0);
      _recurrenceType = RecurrenceType.everyWeek;
      _customInterval = 1;
      _weekNumber = widget.weekNumber ?? 0;
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Lesson' : 'Add Lesson'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Consumer2<SubjectService, TimetableService>(
        builder: (context, subjectService, timetableService, child) {
          final subjects = subjectService.subjects;

          // Set default subject if not editing and subjects available
          if (!isEditing && _selectedSubjectId == -1 && subjects.isNotEmpty) {
            _selectedSubjectId = subjects.first.id;
          }

          if (subjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.subject_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No subjects available',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  const Text('Add subjects first before creating lessons'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Template selector removed

                // Subject selector
                Text('Subject', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: subjects.any((s) => s.id == _selectedSubjectId)
                      ? _selectedSubjectId
                      : subjects.first.id,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.subject),
                  ),
                  items: subjects.map((subject) {
                    final color = subject.colorValue != null
                        ? Color(subject.colorValue!)
                        : AppColors.getDefaultSubjectColor(subject.id);
                    return DropdownMenuItem(
                      value: subject.id,
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(subject.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedSubjectId = value);
                    }
                  },
                  validator: (value) {
                    if (value == null) return 'Please select a subject';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Day of week selector
                Text(
                  'Day of Week',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedDayOfWeek,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  items: List.generate(7, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text(AppConstants.daysOfWeek[index]),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedDayOfWeek = value);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Time selectors
                Text('Time', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimePicker(
                        label: 'Start Time',
                        time: _startTime,
                        onTap: () => _selectTime(true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimePicker(
                        label: 'End Time',
                        time: _endTime,
                        onTap: () => _selectTime(false),
                      ),
                    ),
                  ],
                ),
                if (_endTime.hour * 60 + _endTime.minute <=
                    _startTime.hour * 60 + _startTime.minute)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'End time must be after start time',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Recurrence type
                Text(
                  'Recurrence',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<RecurrenceType>(
                  segments: const [
                    ButtonSegment(
                      value: RecurrenceType.everyWeek,
                      label: Text('Weekly'),
                      icon: Icon(Icons.repeat_one),
                    ),
                    ButtonSegment(
                      value: RecurrenceType.everyTwoWeeks,
                      label: Text('Bi-weekly'),
                      icon: Icon(Icons.repeat),
                    ),
                    ButtonSegment(
                      value: RecurrenceType.custom,
                      label: Text('Custom'),
                      icon: Icon(Icons.tune),
                    ),
                  ],
                  selected: {_recurrenceType},
                  onSelectionChanged: (selected) {
                    setState(() => _recurrenceType = selected.first);
                  },
                ),

                if (_recurrenceType == RecurrenceType.custom) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Every '),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: _customInterval.toString(),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) {
                            final interval = int.tryParse(value);
                            if (interval != null && interval > 0) {
                              _customInterval = interval;
                            }
                          },
                        ),
                      ),
                      const Text(' weeks'),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Week number (show only when bi-weekly selected)
                if (_recurrenceType == RecurrenceType.everyTwoWeeks) ...[
                  Text(
                    'Week Number',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Every Week')),
                      ButtonSegment(value: 1, label: Text('Week 1')),
                      ButtonSegment(value: 2, label: Text('Week 2')),
                    ],
                    selected: {_weekNumber},
                    onSelectionChanged: (selected) {
                      setState(() => _weekNumber = selected.first);
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Notes
                Text(
                  'Notes (Optional)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Add any notes about this lesson...',
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: 24),

                // Conflict warning
                if (_checkForConflicts(timetableService)) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This lesson overlaps with another lesson',
                            style: TextStyle(color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Save button
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _save(timetableService),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Update Lesson' : 'Add Lesson'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          TimeUtils.formatTimeOfDay(time),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _selectTime(bool isStartTime) async {
    final initialTime = isStartTime ? _startTime : _endTime;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = selectedTime;
          // Auto-adjust end time if needed
          final startMinutes = _startTime.hour * 60 + _startTime.minute;
          final endMinutes = _endTime.hour * 60 + _endTime.minute;
          if (endMinutes <= startMinutes) {
            final newEndMinutes =
                startMinutes + AppConstants.defaultLessonDurationMinutes;
            _endTime = TimeOfDay(
              hour: newEndMinutes ~/ 60,
              minute: newEndMinutes % 60,
            );
          }
        } else {
          _endTime = selectedTime;
        }
      });
    }
  }

  bool _checkForConflicts(TimetableService timetableService) {
    if (_selectedSubjectId < 0) return false;

    final tempLesson = Lesson(
      id: widget.lesson?.id ?? 'temp',
      subjectId: _selectedSubjectId,
      dayOfWeek: _selectedDayOfWeek,
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      weekNumber: _weekNumber,
    );

    return timetableService.hasConflicts(tempLesson);
  }

  Future<void> _save(TimetableService timetableService) async {
    if (!_formKey.currentState!.validate()) return;

    // Validate end time is after start time
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        final updatedLesson = widget.lesson!.copyWith(
          subjectId: _selectedSubjectId,
          dayOfWeek: _selectedDayOfWeek,
          startHour: _startTime.hour,
          startMinute: _startTime.minute,
          endHour: _endTime.hour,
          endMinute: _endTime.minute,
          recurrenceType: _recurrenceType,
          customIntervalWeeks: _recurrenceType == RecurrenceType.custom
              ? _customInterval
              : null,
          weekNumber: _weekNumber,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
        await timetableService.updateLesson(updatedLesson);
      } else {
        await timetableService.addLesson(
          subjectId: _selectedSubjectId,
          dayOfWeek: _selectedDayOfWeek,
          startHour: _startTime.hour,
          startMinute: _startTime.minute,
          endHour: _endTime.hour,
          endMinute: _endTime.minute,
          recurrenceType: _recurrenceType,
          customIntervalWeeks: _recurrenceType == RecurrenceType.custom
              ? _customInterval
              : null,
          weekNumber: _weekNumber,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          templateId: null,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Lesson updated' : 'Lesson added'),
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
        title: const Text('Delete Lesson'),
        content: const Text('Are you sure you want to delete this lesson?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TimetableService>().deleteLesson(widget.lesson!.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close form
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
}
