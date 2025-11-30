import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';

/// Widget displaying today's lessons on the home screen
class TodayScheduleCard extends StatelessWidget {
  const TodayScheduleCard({super.key});

  String _formatDate(DateTime date) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final timetableService = Provider.of<TimetableService>(context);
    final subjectService = Provider.of<SubjectService>(context);
    final now = DateTime.now();
    final todayLessons = timetableService.getLessonsForDate(now);

    // Sort by start time
    todayLessons.sort((a, b) {
      final aStart = a.startHour * 60 + a.startMinute;
      final bStart = b.startHour * 60 + b.startMinute;
      return aStart.compareTo(bStart);
    });

    return SingleChildScrollView(
      child: Column(
        children: [
          // Statistics at the top
          if (todayLessons.isNotEmpty)
            TodayStatistics(todayLessons: todayLessons),
          // Schedule card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.today,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Today\'s Schedule',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(now),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Divider(height: 24),
                  if (todayLessons.isEmpty)
                    const EmptyState(
                      icon: Icons.event_available,
                      title: 'No lessons scheduled for today',
                    )
                  else
                    ...todayLessons.map((lesson) {
                      final subject = subjectService.getSubjectById(
                        lesson.subjectId,
                      );
                      final subjectName = subject?.name ?? 'Unknown';
                      final subjectColor = subject?.colorValue != null
                          ? Color(subject!.colorValue!)
                          : null;
                      final now = DateTime.now();
                      final currentMinutes = now.hour * 60 + now.minute;
                      final lessonStart =
                          lesson.startHour * 60 + lesson.startMinute;
                      final lessonEnd = lesson.endHour * 60 + lesson.endMinute;
                      final isOngoing =
                          currentMinutes >= lessonStart &&
                          currentMinutes < lessonEnd;
                      final isPast = currentMinutes >= lessonEnd;
                      final isUpcoming = currentMinutes < lessonStart;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Time indicator
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  lesson.formattedStartTime,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: isOngoing
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isOngoing
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : isPast
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant
                                            : null,
                                      ),
                                ),
                                Text(
                                  lesson.formattedEndTime,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Vertical line with dot
                            Column(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isOngoing
                                        ? Theme.of(context).colorScheme.primary
                                        : isPast
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest
                                        : subjectColor,
                                    shape: BoxShape.circle,
                                    border: isUpcoming
                                        ? Border.all(
                                            color:
                                                subjectColor ??
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                ),
                                if (lesson != todayLessons.last)
                                  Container(
                                    width: 2,
                                    height: 40,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Lesson details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          subjectName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isPast
                                                    ? Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant
                                                    : null,
                                                decoration: isPast
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                        ),
                                      ),
                                      if (isOngoing)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            'NOW',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (lesson.notes != null &&
                                      lesson.notes!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        lesson.notes!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                              fontStyle: FontStyle.italic,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
