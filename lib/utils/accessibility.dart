import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Accessibility utilities for improved screen reader support
class AccessibilityUtils {
  /// Generate semantic label for a lesson card
  static String lessonCardLabel({
    required String subjectName,
    required String startTime,
    required String endTime,
    required String dayName,
    String? roomNumber,
    String? status,
  }) {
    final buffer = StringBuffer();
    buffer.write('$subjectName lesson on $dayName from $startTime to $endTime');

    if (roomNumber != null && roomNumber.isNotEmpty) {
      buffer.write(' in room $roomNumber');
    }

    if (status != null && status.isNotEmpty) {
      buffer.write('. Status: $status');
    }

    return buffer.toString();
  }

  /// Generate semantic label for a subject card
  static String subjectCardLabel({
    required String name,
    required String teacherName,
    int? bookCount,
  }) {
    final buffer = StringBuffer();
    buffer.write('Subject: $name');

    if (teacherName.isNotEmpty) {
      buffer.write(', taught by $teacherName');
    }

    if (bookCount != null && bookCount > 0) {
      buffer.write(
        ', $bookCount ${bookCount == 1 ? "book" : "books"} assigned',
      );
    }

    return buffer.toString();
  }

  /// Generate semantic label for a book card
  static String bookCardLabel({
    required int id,
    required String title,
    String? author,
    List<String>? subjectNames,
  }) {
    final buffer = StringBuffer();
    buffer.write('Book ID $id: $title');

    if (author != null && author.isNotEmpty) {
      buffer.write(' by $author');
    }

    if (subjectNames != null && subjectNames.isNotEmpty) {
      buffer.write('. Used in ${subjectNames.join(", ")}');
    }

    return buffer.toString();
  }

  /// Generate semantic label for time picker
  static String timePickerLabel(int hour, int minute) {
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  /// Generate semantic label for date
  static String dateLabel(DateTime date) {
    final weekday = _getWeekdayName(date.weekday);
    final month = _getMonthName(date.month);
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  /// Generate semantic hint for drag and drop
  static String dragAndDropHint(String itemName) {
    return 'Double tap and hold to reorder $itemName';
  }

  /// Generate semantic label for status badge
  static String statusBadgeLabel(String status) {
    switch (status.toLowerCase()) {
      case 'cancelled':
        return 'Lesson cancelled';
      case 'modified':
        return 'Lesson time or location modified';
      case 'rescheduled':
        return 'Lesson rescheduled to different date';
      case 'normal':
        return 'Lesson scheduled as normal';
      default:
        return 'Lesson status: $status';
    }
  }

  /// Generate semantic label for color picker
  static String colorLabel(Color color) {
    // Convert to HSL for better color description
    final hsl = HSLColor.fromColor(color);
    final hue = hsl.hue;
    final lightness = hsl.lightness;

    String colorName;
    if (hue < 15 || hue >= 345) {
      colorName = 'Red';
    } else if (hue < 45) {
      colorName = 'Orange';
    } else if (hue < 75) {
      colorName = 'Yellow';
    } else if (hue < 165) {
      colorName = 'Green';
    } else if (hue < 255) {
      colorName = 'Blue';
    } else if (hue < 285) {
      colorName = 'Purple';
    } else {
      colorName = 'Pink';
    }

    if (lightness < 0.3) {
      colorName = 'Dark $colorName';
    } else if (lightness > 0.7) {
      colorName = 'Light $colorName';
    }

    return colorName;
  }

  static String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  static String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return 'Unknown';
    }
  }
}

/// Contrast ratio checker for accessibility compliance
class ContrastChecker {
  /// Check if color combination meets WCAG AA standard (4.5:1 for normal text)
  static bool meetsWCAGAA(Color foreground, Color background) {
    return _getContrastRatio(foreground, background) >= 4.5;
  }

  /// Check if color combination meets WCAG AAA standard (7:1 for normal text)
  static bool meetsWCAGAAA(Color foreground, Color background) {
    return _getContrastRatio(foreground, background) >= 7.0;
  }

  /// Get contrast ratio between two colors
  static double _getContrastRatio(Color color1, Color color2) {
    final l1 = _getRelativeLuminance(color1);
    final l2 = _getRelativeLuminance(color2);

    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculate relative luminance of a color
  static double _getRelativeLuminance(Color color) {
    final r = _convertToLinear(color.r);
    final g = _convertToLinear(color.g);
    final b = _convertToLinear(color.b);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _convertToLinear(double value) {
    if (value <= 0.03928) {
      return value / 12.92;
    }
    return math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Get readable text color (black or white) for given background
  static Color getReadableTextColor(Color background) {
    final blackContrast = _getContrastRatio(Colors.black, background);
    final whiteContrast = _getContrastRatio(Colors.white, background);

    return blackContrast > whiteContrast ? Colors.black : Colors.white;
  }
}

// using dart:math pow instead of a custom extension
