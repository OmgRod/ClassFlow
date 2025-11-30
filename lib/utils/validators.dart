/// Enhanced data validation utilities with detailed error messages
class Validators {
  // Subject name validation
  static String? validateSubjectName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Subject name is required';
    }

    if (value.trim().length < 2) {
      return 'Subject name must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'Subject name must not exceed 50 characters';
    }

    // Check for invalid characters
    if (RegExp(r'[<>:"/\\|?*]').hasMatch(value)) {
      return 'Subject name contains invalid characters';
    }

    return null;
  }

  // Book title validation
  static String? validateBookTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Book title is required';
    }

    if (value.trim().length < 2) {
      return 'Book title must be at least 2 characters';
    }

    if (value.length > 100) {
      return 'Book title must not exceed 100 characters';
    }

    return null;
  }

  // Book ID validation
  static String? validateBookId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Book ID is required';
    }

    final id = int.tryParse(value.trim());
    if (id == null) {
      return 'Book ID must be a valid number';
    }

    if (id < 1) {
      return 'Book ID must be greater than 0';
    }

    if (id > 999999) {
      return 'Book ID must not exceed 999999';
    }

    return null;
  }

  // Lesson notes validation
  static String? validateLessonNotes(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Notes are optional
    }

    if (value.length > 500) {
      return 'Notes must not exceed 500 characters';
    }

    return null;
  }

  // Time validation
  static String? validateTime(int? hour, int? minute) {
    if (hour == null || minute == null) {
      return 'Time is required';
    }

    if (hour < 0 || hour > 23) {
      return 'Hour must be between 0 and 23';
    }

    if (minute < 0 || minute > 59) {
      return 'Minute must be between 0 and 59';
    }

    return null;
  }

  // Time range validation
  static String? validateTimeRange(
    int startHour,
    int startMinute,
    int endHour,
    int endMinute,
  ) {
    final startError = validateTime(startHour, startMinute);
    if (startError != null) return startError;

    final endError = validateTime(endHour, endMinute);
    if (endError != null) return endError;

    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    if (endMinutes <= startMinutes) {
      return 'End time must be after start time';
    }

    if (endMinutes - startMinutes < 15) {
      return 'Lesson must be at least 15 minutes long';
    }

    if (endMinutes - startMinutes > 360) {
      return 'Lesson duration cannot exceed 6 hours';
    }

    return null;
  }

  // Room number validation
  static String? validateRoomNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Room number is optional
    }

    if (value.length > 20) {
      return 'Room number must not exceed 20 characters';
    }

    return null;
  }

  // Recurrence interval validation
  static String? validateRecurrenceInterval(int? value) {
    if (value == null) {
      return 'Recurrence interval is required';
    }

    if (value < 1) {
      return 'Recurrence interval must be at least 1';
    }

    if (value > 52) {
      return 'Recurrence interval must not exceed 52 weeks';
    }

    return null;
  }

  // Template name validation
  static String? validateTemplateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Template name is required';
    }

    if (value.trim().length < 2) {
      return 'Template name must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'Template name must not exceed 50 characters';
    }

    return null;
  }

  // Break time name validation
  static String? validateBreakTimeName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Break time name is required';
    }

    if (value.trim().length < 2) {
      return 'Break time name must be at least 2 characters';
    }

    if (value.length > 30) {
      return 'Break time name must not exceed 30 characters';
    }

    return null;
  }

  // Email validation (for future cloud sync)
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation (for future cloud sync)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (value.length > 128) {
      return 'Password must not exceed 128 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  // Duplicate check helper
  static String? checkDuplicate<T>({
    required String value,
    required List<T> items,
    required String Function(T) getName,
    T? excludeItem,
    required String itemType,
  }) {
    final trimmedValue = value.trim().toLowerCase();

    final duplicate = items.any((item) {
      if (excludeItem != null && item == excludeItem) {
        return false;
      }
      return getName(item).trim().toLowerCase() == trimmedValue;
    });

    if (duplicate) {
      return 'A $itemType with this name already exists';
    }

    return null;
  }
}
