import 'package:flutter/foundation.dart';
import '../models/break_time.dart';
import 'database_service.dart';
import 'package:uuid/uuid.dart';

class BreakTimeService extends ChangeNotifier {
  List<BreakTime> _breaks = [];

  List<BreakTime> get breaks => _breaks;

  BreakTimeService() {
    _loadBreaks();
  }

  void _loadBreaks() {
    final data = DatabaseService.settings['breakTimes'] as List?;
    if (data != null) {
      _breaks = data
          .map((b) => BreakTime.fromJson(b as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _saveBreaks() async {
    DatabaseService.settings['breakTimes'] = _breaks
        .map((b) => b.toJson())
        .toList();
    await DatabaseService.save();
    notifyListeners();
  }

  /// Add a new break time
  Future<BreakTime> addBreak({
    required String name,
    required int dayOfWeek,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    int weekNumber = 0,
  }) async {
    final breakTime = BreakTime(
      id: const Uuid().v4(),
      name: name,
      dayOfWeek: dayOfWeek,
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
      weekNumber: weekNumber,
    );

    _breaks.add(breakTime);
    await _saveBreaks();
    return breakTime;
  }

  /// Update an existing break time
  Future<void> updateBreak(BreakTime breakTime) async {
    final index = _breaks.indexWhere((b) => b.id == breakTime.id);
    if (index != -1) {
      _breaks[index] = breakTime;
      await _saveBreaks();
    }
  }

  /// Delete a break time
  Future<void> deleteBreak(String id) async {
    _breaks.removeWhere((b) => b.id == id);
    await _saveBreaks();
  }

  /// Get break by ID
  BreakTime? getBreakById(String id) {
    try {
      return _breaks.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get breaks for a specific day
  List<BreakTime> getBreaksForDay(int dayOfWeek, {int? weekNumber}) {
    return _breaks.where((b) {
      if (b.dayOfWeek != dayOfWeek) return false;
      if (weekNumber != null &&
          b.weekNumber != 0 &&
          b.weekNumber != weekNumber) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) {
      final aTime = a.startHour * 60 + a.startMinute;
      final bTime = b.startHour * 60 + b.startMinute;
      return aTime.compareTo(bTime);
    });
  }

  /// Get all breaks sorted by day and time
  List<BreakTime> get sortedBreaks {
    final sorted = List<BreakTime>.from(_breaks);
    sorted.sort((a, b) {
      if (a.dayOfWeek != b.dayOfWeek) {
        return a.dayOfWeek.compareTo(b.dayOfWeek);
      }
      final aTime = a.startHour * 60 + a.startMinute;
      final bTime = b.startHour * 60 + b.startMinute;
      return aTime.compareTo(bTime);
    });
    return sorted;
  }
}
