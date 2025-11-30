# ClassFlow Roadmap

This roadmap outlines planned features and improvements for ClassFlow. Items are organized by priority and complexity to guide future development.

---

## 🚀 Version 0.3.0 - Quick Wins & Polish

### UI/UX Improvements

- [ ] **Search & filtering** - Add search bars to subjects, books, and timetable lists
- [ ] **Batch operations** - Enable multi-select for bulk delete/edit of subjects and books
- [ ] **Onboarding improvements** - Add interactive tutorial for first-time users (beyond current modal)
- [ ] **Accessibility enhancements** - Improve screen reader support, semantic labels, and contrast ratios
- [ ] **Animations & transitions** - Polish page transitions and add subtle micro-interactions

### Data Management

- [ ] **Backup & restore to cloud** - iCloud/Google Drive integration for automatic backups
- [ ] **Data validation** - Add stricter input validation and error messages for malformed data
- [ ] **Undo/redo functionality** - Implement action history for accidental deletions
- [ ] **Archive system** - Archive old subjects/books instead of permanently deleting

### Timetable Enhancements

- [ ] **Today view widget** - Show today's schedule prominently on home screen
- [ ] **Lesson notes** - Add optional notes field to lessons for homework/reminders
- [ ] **Break time blocks** - Explicitly add break/lunch periods to timetable
- [ ] **Time zone support** - Handle timetable display for users traveling across time zones

---

## 📱 Version 0.4.0 - Mobile & Cross-Platform

### Platform-Specific Features

- [ ] **iOS home screen widgets** - Show today's timetable on iOS home screen
- [ ] **Android widgets** - Timetable widget for Android home screen
- [ ] **Desktop tray integration** - System tray icon with quick access to today's schedule (Windows/macOS/Linux)
- [ ] **Web app optimization** - Improve responsive design and PWA capabilities
- [ ] **Wear OS companion** - Basic timetable viewer for smartwatches

### Notifications & Reminders

- [ ] **Lesson reminders** - Push notifications X minutes before lessons start
- [ ] **Assignment deadlines** - Track and notify about homework/assignment due dates
- [ ] **Custom alerts** - User-defined notifications (e.g., "Bring textbook for Monday's class")
- [ ] **Do Not Disturb mode** - Auto-silence during lessons

### QR Code Improvements

- [ ] **Batch QR generation** - Generate QR codes for all books at once as PDF
- [ ] **QR code templates** - Custom designs, colors, and logo embedding
- [ ] **NFC tag support** - Alternative to QR codes using NFC tags
- [ ] **Barcode support** - Scan ISBN barcodes from physical books

---

## 🎓 Version 0.5.0 - Academic Features

### Grade & Assignment Tracking

- [ ] **Gradebook** - Track grades/scores per subject with weighted categories
- [ ] **Assignment manager** - Add homework/project tasks with due dates and completion tracking
- [ ] **GPA calculator** - Calculate semester/cumulative GPA based on grades
- [ ] **Progress reports** - Visual charts showing performance trends over time

### Study Tools

- [ ] **Study timer** - Pomodoro-style timer linked to subjects
- [ ] **Flashcards** - Create and review flashcards per subject
- [ ] **Note-taking** - In-app markdown notes attached to subjects or lessons
- [ ] **Calendar integration** - Sync lessons and assignments with device calendar (Google Calendar, Apple Calendar)

### Collaboration

- [ ] **Share timetables** - Export timetable as shareable link or image
- [ ] **Class groups** - Import shared subject/book data from peers
- [ ] **Teacher mode** - Special view for educators managing multiple class sections

---

## 🔧 Version 0.6.0 - Advanced & Integration

### Cloud & Sync

- [ ] **Multi-device sync** - Real-time sync across devices using Firebase/Supabase
- [ ] **Web dashboard** - Browser-based interface for viewing/editing timetable
- [ ] **Account system** - Optional user accounts for cloud features (with offline-first design)

### AI & Automation

- [ ] **Smart timetable suggestions** - Auto-generate optimal timetable from constraints
- [ ] **Conflict resolver** - AI-powered suggestions to resolve scheduling conflicts
- [ ] **OCR for timetables** - Scan printed timetables and auto-populate data
- [ ] **Natural language input** - Add lessons via voice/text commands ("Add Math on Monday 9 AM")

### Integrations

- [ ] **Google Classroom integration** - Import classes, assignments, and deadlines
- [ ] **Microsoft Teams/Outlook** - Sync with school/university calendar systems
- [ ] **Notion/Obsidian export** - Export structured data to external note-taking apps
- [ ] **Canvas/Moodle support** - Pull course schedules from LMS platforms

### Customization

- [ ] **Custom themes** - Full theme editor with color palettes and fonts
- [ ] **Layout presets** - Alternative home screen layouts (grid, list, calendar-first)
- [ ] **Plugin system** - Allow community-built extensions for specialized workflows

---

## 🛠️ Technical Improvements

### Performance & Reliability

- [ ] **Offline-first architecture** - Ensure full functionality without internet
- [ ] **Database migration system** - Seamless Hive schema upgrades between versions
- [ ] **Error reporting** - Crash analytics and diagnostics (opt-in)
- [ ] **Performance profiling** - Optimize app startup and rendering times

### Testing & Quality

- [ ] **Unit tests** - Comprehensive test coverage for services and models
- [ ] **Widget tests** - UI component testing for screens
- [ ] **Integration tests** - End-to-end user flow testing
- [ ] **Automated CI/CD** - Continuous testing and deployment pipeline

### Developer Experience

- [ ] **API documentation** - Internal code documentation for contributors
- [ ] **Contribution guidelines** - Clear guidelines for open-source contributions
- [ ] **Localization framework** - i18n support for multiple languages
- [ ] **Automated release notes** - Generate changelogs from commit messages

---

## 🌟 Future Exploration (Backlog)

These are experimental ideas for long-term consideration:

- **AR room scanner** - Use AR to scan classroom layout and auto-assign seats
- **Gamification** - Earn badges/achievements for consistent attendance or study streaks
- **Social features** - Connect with classmates, share notes, and form study groups
- **Voice assistant integration** - Alexa/Google Assistant skills for hands-free timetable queries
- **Exam countdown** - Visual countdown to finals/midterms with study plan generation
- **Resource library** - Attach PDFs, links, and files to subjects
- **Attendance tracker** - Mark attendance per lesson with analytics
- **Virtual study rooms** - Video chat integration for group study sessions
- **Habit tracker** - Track study habits and productivity metrics
- **Parental controls** - Guardian access to view child's schedule and progress

---

## 📝 Contributing

Have an idea not listed here? Open an issue or discussion on GitHub! We welcome community feedback and contributions.

---

## Legend

- ✅ Completed
- 🚧 In Progress
- 📅 Planned
- 💡 Under Consideration
- ❌ Deprioritized/Cancelled

---

**Last Updated:** November 30, 2025  
**Current Version:** 0.2.0
