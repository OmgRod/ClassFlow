/// Service for exporting timetable data in various formats
class ExportService {
  /// Export timetable to CSV format
  static String exportToCSV({
    required List<dynamic> lessons,
    required Map<int, String> subjectNames,
  }) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Day,Start Time,End Time,Subject,Notes');

    // Sort lessons by day and time
    final sortedLessons = List.from(lessons);
    sortedLessons.sort((a, b) {
      final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
      if (dayCompare != 0) return dayCompare;
      final startCompare = a.startHour.compareTo(b.startHour);
      if (startCompare != 0) return startCompare;
      return a.startMinute.compareTo(b.startMinute);
    });

    // Data rows
    for (final lesson in sortedLessons) {
      final day = _getDayName(lesson.dayOfWeek);
      final startTime =
          '${_padZero(lesson.startHour)}:${_padZero(lesson.startMinute)}';
      final endTime =
          '${_padZero(lesson.endHour)}:${_padZero(lesson.endMinute)}';
      final subject = subjectNames[lesson.subjectId] ?? 'Unknown';
      final notes = (lesson.notes ?? '')
          .replaceAll(',', ';')
          .replaceAll('\n', ' ');

      buffer.writeln('$day,$startTime,$endTime,$subject,$notes');
    }

    return buffer.toString();
  }

  /// Export timetable to iCal format
  static String exportToICal({
    required List<dynamic> lessons,
    required Map<int, String> subjectNames,
    required DateTime startDate,
  }) {
    final buffer = StringBuffer();

    // iCal header
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//ClassFlow//Timetable//EN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('X-WR-CALNAME:ClassFlow Timetable');
    buffer.writeln('X-WR-TIMEZONE:UTC');

    // Generate events for next 16 weeks (one semester)
    for (final lesson in lessons) {
      for (int week = 0; week < 16; week++) {
        final eventDate = _getNextWeekday(startDate, lesson.dayOfWeek, week);
        final uid = 'classflow-${lesson.id}-$week@classflow.app';

        buffer.writeln('BEGIN:VEVENT');
        buffer.writeln('UID:$uid');
        buffer.writeln('DTSTAMP:${_formatDateTimeICal(DateTime.now())}');
        buffer.writeln(
          'DTSTART:${_formatDateTimeICal(eventDate.add(Duration(hours: lesson.startHour, minutes: lesson.startMinute)))}',
        );
        buffer.writeln(
          'DTEND:${_formatDateTimeICal(eventDate.add(Duration(hours: lesson.endHour, minutes: lesson.endMinute)))}',
        );
        buffer.writeln('SUMMARY:${subjectNames[lesson.subjectId] ?? 'Lesson'}');
        if (lesson.notes != null && lesson.notes.isNotEmpty) {
          buffer.writeln('DESCRIPTION:${lesson.notes.replaceAll('\n', '\\n')}');
        }
        buffer.writeln('STATUS:CONFIRMED');
        buffer.writeln('SEQUENCE:0');
        buffer.writeln('END:VEVENT');
      }
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  /// Get day name from day number (1-7)
  static String _getDayName(int dayOfWeek) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dayOfWeek - 1];
  }

  /// Pad single digit numbers with zero
  static String _padZero(int number) {
    return number.toString().padLeft(2, '0');
  }

  /// Get the next occurrence of a weekday
  static DateTime _getNextWeekday(
    DateTime start,
    int targetWeekday,
    int weeksAhead,
  ) {
    final daysUntilTarget = (targetWeekday - start.weekday + 7) % 7;
    return start.add(Duration(days: daysUntilTarget + (weeksAhead * 7)));
  }

  /// Format DateTime for iCal (YYYYMMDDTHHMMSS)
  static String _formatDateTimeICal(DateTime dt) {
    return '${dt.year}${_padZero(dt.month)}${_padZero(dt.day)}T${_padZero(dt.hour)}${_padZero(dt.minute)}${_padZero(dt.second)}Z';
  }
}
