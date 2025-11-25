import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class DatabaseService {
  static const String subjectsBoxName = 'subjects';
  static const String booksBoxName = 'books';
  static const String lessonsBoxName = 'lessons';
  static const String templatesBoxName = 'templates';
  static const String settingsBoxName = 'settings';

  static late Box<Subject> subjectsBox;
  static late Box<Book> booksBox;
  static late Box<Lesson> lessonsBox;
  static late Box<LessonTemplate> templatesBox;
  static late Box settingsBox;
  static late Box<SpecialLesson> specialLessonsBox;

  /// Initialize Hive and register adapters
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(SubjectAdapter());
    Hive.registerAdapter(BookAdapter());
    Hive.registerAdapter(LessonAdapter());
    Hive.registerAdapter(RecurrenceTypeAdapter());
    Hive.registerAdapter(LessonTemplateAdapter());
    Hive.registerAdapter(SpecialLessonAdapter());

    // Open boxes
    subjectsBox = await Hive.openBox<Subject>(subjectsBoxName);
    booksBox = await Hive.openBox<Book>(booksBoxName);
    lessonsBox = await Hive.openBox<Lesson>(lessonsBoxName);
    templatesBox = await Hive.openBox<LessonTemplate>(templatesBoxName);
    settingsBox = await Hive.openBox(settingsBoxName);
    // special lessons
    specialLessonsBox = await Hive.openBox<SpecialLesson>('special_lessons');
  }

  /// Close all boxes
  static Future<void> close() async {
    await subjectsBox.close();
    await booksBox.close();
    await lessonsBox.close();
    await templatesBox.close();
    await specialLessonsBox.close();
  }

  /// Clear all data
  static Future<void> clearAll() async {
    await subjectsBox.clear();
    await booksBox.clear();
    await lessonsBox.clear();
    await templatesBox.clear();
    await specialLessonsBox.clear();
  }
}
