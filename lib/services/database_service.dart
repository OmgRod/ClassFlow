import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/models.dart';
import '../utils/file_utils.dart';

/// JSON-backed replacement for the old Hive-based storage.
///
/// All data is stored in a single `db.json` file under the
/// app's directory (managed by `FileUtils`). This makes the
/// database human-readable and easy to export/debug.
class DatabaseService {
  static const String _dbFileName = 'db.json';

  static bool _initialized = false;

  static final List<Subject> subjects = [];
  static final List<Book> books = [];
  static final List<Lesson> lessons = [];
  static final Map<String, dynamic> settings = {};

  /// Initialize the JSON database by loading from disk or
  /// creating an empty structure.
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final appDir = await FileUtils.getAppDirectory();
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }

      final dbFile = File(p.join(appDir.path, _dbFileName));

      if (await dbFile.exists()) {
        final raw = await dbFile.readAsString();
        if (raw.trim().isNotEmpty) {
          final decoded = json.decode(raw) as Map<String, dynamic>;
          _loadFromMap(decoded);
        }
      }

      _initialized = true;
      debugPrint(
        'DatabaseService(JSON): initialized subjects=${subjects.length}, books=${books.length}, lessons=${lessons.length}, settingsKeys=${settings.keys.length}',
      );
    } catch (e, st) {
      debugPrint('DatabaseService(JSON).initialize() failed: $e\n$st');
      rethrow;
    }
  }

  /// Persist the in-memory state to `db.json`.
  static Future<void> save() async {
    try {
      final appDir = await FileUtils.getAppDirectory();
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      final dbFile = File(p.join(appDir.path, _dbFileName));
      final map = _toMap();
      await dbFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(map),
        flush: true,
      );
    } catch (e, st) {
      debugPrint('DatabaseService(JSON).save() failed: $e\n$st');
      rethrow;
    }
  }

  /// Clear all data in memory and on disk.
  static Future<void> clearAll() async {
    subjects.clear();
    books.clear();
    lessons.clear();
    settings.clear();
    await save();
  }

  static void _loadFromMap(Map<String, dynamic> data) {
    subjects
      ..clear()
      ..addAll(
        (data['subjects'] as List<dynamic>? ?? []).map(
          (e) => Subject.fromJson(e as Map<String, dynamic>),
        ),
      );

    books
      ..clear()
      ..addAll(
        (data['books'] as List<dynamic>? ?? []).map(
          (e) => Book.fromJson(e as Map<String, dynamic>),
        ),
      );

    lessons
      ..clear()
      ..addAll(
        (data['lessons'] as List<dynamic>? ?? []).map(
          (e) => Lesson.fromJson(e as Map<String, dynamic>),
        ),
      );

    settings
      ..clear()
      ..addAll((data['settings'] as Map<String, dynamic>? ?? {}));
  }

  static Map<String, dynamic> _toMap() {
    return {
      'subjects': subjects.map((s) => s.toJson()).toList(),
      'books': books.map((b) => b.toJson()).toList(),
      'lessons': lessons.map((l) => l.toJson()).toList(),
      'settings': settings,
    };
  }
}
