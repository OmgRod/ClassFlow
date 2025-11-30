import 'package:flutter/material.dart';

enum LessonStatus {
  normal,
  cancelled,
  modified,
  rescheduled;

  String get displayName {
    switch (this) {
      case LessonStatus.normal:
        return 'Normal';
      case LessonStatus.cancelled:
        return 'Cancelled';
      case LessonStatus.modified:
        return 'Modified';
      case LessonStatus.rescheduled:
        return 'Rescheduled';
    }
  }

  IconData get icon {
    switch (this) {
      case LessonStatus.normal:
        return Icons.check_circle_outline;
      case LessonStatus.cancelled:
        return Icons.cancel_outlined;
      case LessonStatus.modified:
        return Icons.edit_outlined;
      case LessonStatus.rescheduled:
        return Icons.event_repeat;
    }
  }

  Color get color {
    switch (this) {
      case LessonStatus.normal:
        return const Color(0xFF4CAF50); // Green
      case LessonStatus.cancelled:
        return const Color(0xFFF44336); // Red
      case LessonStatus.modified:
        return const Color(0xFFFF9800); // Orange
      case LessonStatus.rescheduled:
        return const Color(0xFF2196F3); // Blue
    }
  }
}
