# DetentionSafe

A Flutter app for managing subjects, books with QR codes, and timetables.

## Features

### Subjects Management
- Add, edit, and delete subjects
- Each subject has:
  - ID (number)
  - Name (full uppercase, no spaces)
  - Book ID(s) (multiple allowed per subject)
  - Optional color for GUI highlighting
  - Auto-generated code: `[subjectID]-[bookID]-[FULLNAME]`

### Books & QR Codes
- Generate QR codes for each book under a subject
- QR codes contain the format: `[subjectID]-[bookID]-[FULLNAME]`
- Save or share QR codes as PNG images
- Subtle mode for less visible QR codes
- High-accuracy QR code scanner via camera
- Scanner displays subject/book info on successful scan

### Timetable System
- Built-in timetable creator
- Features:
  - Add lessons with start/end times and day of week
  - Assign lessons to subjects
  - Set recurrence: every week, every 2 weeks, or custom interval
  - Week 1/Week 2 support for bi-weekly timetables
  - Create templates for repeated time blocks
- Weekly calendar view
- Color-coded subjects
- Tap a lesson to edit or delete
- Conflict detection for overlapping lessons
- Copy lessons from one week to another

### Database & Storage
- Uses Hive for local storage
- Stores:
  - Subjects
  - Books
  - Lessons/timetable
  - Lesson templates
- Full CRUD operations for all entities

## Dependencies

- `hive` & `hive_flutter` - Local database storage
- `qr_flutter` - QR code generation
- `mobile_scanner` - Camera-based QR code scanning
- `table_calendar` - Calendar/timetable view
- `flutter_colorpicker` - Color selection for subjects
- `provider` - State management
- `share_plus` - Share QR code images
- `path_provider` - File system access
- `uuid` - Unique ID generation
- `intl` - Date/time formatting

## Getting Started

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Generate Hive adapters (if modifying models):
   ```bash
   flutter pub run build_runner build
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── subject.dart          # Subject model
│   ├── book.dart             # Book model
│   ├── lesson.dart           # Lesson model
│   └── lesson_template.dart  # Lesson template model
├── services/                 # Business logic
│   ├── database_service.dart # Hive initialization
│   ├── subject_service.dart  # Subject CRUD
│   ├── book_service.dart     # Book CRUD
│   └── timetable_service.dart# Lesson/template CRUD
├── screens/                  # UI screens
│   ├── home_screen.dart      # Main navigation
│   ├── subjects/             # Subject management screens
│   ├── books/                # Books & QR screens
│   ├── timetable/            # Timetable screens
│   └── scanner/              # QR scanner screen
├── widgets/                  # Reusable widgets
└── utils/                    # Utilities
    ├── theme.dart            # App theme
    └── constants.dart        # App constants
```

## Future Enhancements

- Import iCal/ICS feeds
- Manual import via CSV or JSON
- Export timetable data
- Dark mode support
- Cloud sync
