import 'package:flutter/material.dart';
import '../models/models.dart';

/// Statistics cards for Today view showing lesson summary
class TodayStatistics extends StatelessWidget {
  final List<Lesson> todayLessons;

  const TodayStatistics({super.key, required this.todayLessons});

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;

    // Calculate statistics
    final totalLessons = todayLessons.length;
    final completedLessons = todayLessons.where((lesson) {
      final endMinutes = lesson.endTime.hour * 60 + lesson.endTime.minute;
      return endMinutes <= currentMinutes;
    }).length;

    // Find next lesson
    Lesson? nextLesson;
    Duration? timeUntilNext;
    for (final lesson in todayLessons) {
      final startMinutes = lesson.startTime.hour * 60 + lesson.startTime.minute;
      if (startMinutes > currentMinutes) {
        nextLesson = lesson;
        final minutesUntil = startMinutes - currentMinutes;
        timeUntilNext = Duration(minutes: minutesUntil);
        break;
      }
    }

    // Calculate total free time (gaps between lessons)
    int totalFreeMinutes = 0;
    if (todayLessons.length > 1) {
      for (int i = 0; i < todayLessons.length - 1; i++) {
        final currentEnd =
            todayLessons[i].endTime.hour * 60 + todayLessons[i].endTime.minute;
        final nextStart =
            todayLessons[i + 1].startTime.hour * 60 +
            todayLessons[i + 1].startTime.minute;
        final gap = nextStart - currentEnd;
        if (gap > 0) totalFreeMinutes += gap;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Total Lessons
          Expanded(
            child: _StatCard(
              icon: Icons.book_outlined,
              label: 'Total',
              value: '$completedLessons/$totalLessons',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          // Next Lesson
          Expanded(
            child: _StatCard(
              icon: Icons.schedule,
              label: 'Next',
              value: nextLesson != null && timeUntilNext != null
                  ? _formatDuration(timeUntilNext)
                  : 'None',
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          // Free Time
          Expanded(
            child: _StatCard(
              icon: Icons.free_breakfast,
              label: 'Free',
              value: totalFreeMinutes > 0
                  ? _formatMinutes(totalFreeMinutes)
                  : 'None',
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
