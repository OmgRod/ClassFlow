import 'package:flutter/material.dart';

class AppConstants {
  // App info
  static const String appName = 'ClassFlow';
  static const String appVersion = '0.1.1';

  // Days of week
  static const List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> daysOfWeekShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Get day name from weekday (1 = Monday, 7 = Sunday)
  static String getDayName(int dayOfWeek) {
    if (dayOfWeek < 1 || dayOfWeek > 7) return '';
    return daysOfWeek[dayOfWeek - 1];
  }

  /// Get short day name from weekday
  static String getDayShortName(int dayOfWeek) {
    if (dayOfWeek < 1 || dayOfWeek > 7) return '';
    return daysOfWeekShort[dayOfWeek - 1];
  }

  // Time constants
  static const int dayStartHour = 7;
  static const int dayEndHour = 18;
  static const int defaultLessonDurationMinutes = 60;

  // QR Code settings
  static const double qrCodeSize = 200.0;
  static const double qrCodeSubtleOpacity = 0.3; // For subtle QR codes
}

class TimeUtils {
  /// Format time as HH:MM
  static String formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Format TimeOfDay as HH:MM
  static String formatTimeOfDay(TimeOfDay time) {
    return formatTime(time.hour, time.minute);
  }

  /// Parse HH:MM string to TimeOfDay
  static TimeOfDay? parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  /// Calculate duration in minutes between two times
  static int durationInMinutes(TimeOfDay start, TimeOfDay end) {
    return (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
  }

  /// Check if time1 is before time2
  static bool isBefore(TimeOfDay time1, TimeOfDay time2) {
    return time1.hour < time2.hour ||
        (time1.hour == time2.hour && time1.minute < time2.minute);
  }

  /// Format duration in minutes as human readable string
  static String formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '$mins min';
    if (mins == 0) return '$hours hr';
    return '$hours hr $mins min';
  }
}
