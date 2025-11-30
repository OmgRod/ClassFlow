import 'package:flutter/foundation.dart';
import 'database_service.dart';

/// Service for handling time zone conversions and display preferences
class TimezoneService extends ChangeNotifier {
  String _userTimezone = 'local';
  String _displayTimezone = 'local';
  bool _autoDetectTimezone = true;
  int _timezoneOffset = 0; // Minutes offset from UTC

  TimezoneService() {
    _loadSettings();
  }

  String get userTimezone => _userTimezone;
  String get displayTimezone => _displayTimezone;
  bool get autoDetectTimezone => _autoDetectTimezone;
  int get timezoneOffset => _timezoneOffset;

  Future<void> _loadSettings() async {
    _userTimezone =
        DatabaseService.settings['userTimezone'] as String? ?? 'local';
    _displayTimezone =
        DatabaseService.settings['displayTimezone'] as String? ?? 'local';
    _autoDetectTimezone =
        DatabaseService.settings['autoDetectTimezone'] as bool? ?? true;
    _timezoneOffset = DatabaseService.settings['timezoneOffset'] as int? ?? 0;

    if (_autoDetectTimezone) {
      _detectCurrentTimezone();
    }

    notifyListeners();
  }

  Future<void> _saveSettings() async {
    DatabaseService.settings['userTimezone'] = _userTimezone;
    DatabaseService.settings['displayTimezone'] = _displayTimezone;
    DatabaseService.settings['autoDetectTimezone'] = _autoDetectTimezone;
    DatabaseService.settings['timezoneOffset'] = _timezoneOffset;
    await DatabaseService.save();
    notifyListeners();
  }

  /// Detect current device timezone
  void _detectCurrentTimezone() {
    final now = DateTime.now();
    final utcNow = now.toUtc();
    _timezoneOffset = now.difference(utcNow).inMinutes;
  }

  /// Set user's home timezone
  Future<void> setUserTimezone(String timezone, int offsetMinutes) async {
    _userTimezone = timezone;
    _timezoneOffset = offsetMinutes;
    await _saveSettings();
  }

  /// Set display timezone (for when traveling)
  Future<void> setDisplayTimezone(String timezone) async {
    _displayTimezone = timezone;
    await _saveSettings();
  }

  /// Toggle auto-detect timezone
  Future<void> setAutoDetect(bool enabled) async {
    _autoDetectTimezone = enabled;
    if (enabled) {
      _detectCurrentTimezone();
    }
    await _saveSettings();
  }

  /// Convert lesson time to display timezone
  DateTime convertToDisplayTime(DateTime lessonTime) {
    if (_displayTimezone == 'local' || _displayTimezone == _userTimezone) {
      return lessonTime;
    }

    // Basic timezone conversion (simplified)
    // In production, use timezone package for accurate conversions
    return lessonTime.add(Duration(minutes: _timezoneOffset));
  }

  /// Get timezone offset string (e.g., "UTC+5:30" or "UTC-8:00")
  String getTimezoneOffsetString() {
    final hours = _timezoneOffset ~/ 60;
    final minutes = _timezoneOffset.abs() % 60;
    final sign = _timezoneOffset >= 0 ? '+' : '-';

    if (minutes == 0) {
      return 'UTC$sign${hours.abs()}:00';
    }
    return 'UTC$sign${hours.abs()}:${minutes.toString().padLeft(2, '0')}';
  }

  /// Check if user is in a different timezone than home
  bool get isTraveling =>
      _displayTimezone != _userTimezone && _displayTimezone != 'local';

  /// Get time difference message for traveling users
  String getTimeDifferenceMessage() {
    if (!isTraveling) return '';

    final hours = _timezoneOffset ~/ 60;
    if (hours == 0) return 'Same time as home';

    final hoursAbs = hours.abs();
    if (hours > 0) {
      return '$hoursAbs ${hoursAbs == 1 ? "hour" : "hours"} ahead of home';
    }
    return '$hoursAbs ${hoursAbs == 1 ? "hour" : "hours"} behind home';
  }

  /// Common timezones list
  static const List<TimezoneInfo> commonTimezones = [
    TimezoneInfo('Local (Auto-detect)', 'local', 0),
    TimezoneInfo('UTC', 'UTC', 0),
    TimezoneInfo('Eastern Time (US)', 'America/New_York', -300),
    TimezoneInfo('Central Time (US)', 'America/Chicago', -360),
    TimezoneInfo('Mountain Time (US)', 'America/Denver', -420),
    TimezoneInfo('Pacific Time (US)', 'America/Los_Angeles', -480),
    TimezoneInfo('London (GMT)', 'Europe/London', 0),
    TimezoneInfo('Paris (CET)', 'Europe/Paris', 60),
    TimezoneInfo('Tokyo (JST)', 'Asia/Tokyo', 540),
    TimezoneInfo('Sydney (AEDT)', 'Australia/Sydney', 660),
    TimezoneInfo('India (IST)', 'Asia/Kolkata', 330),
    TimezoneInfo('Dubai (GST)', 'Asia/Dubai', 240),
  ];
}

class TimezoneInfo {
  final String displayName;
  final String identifier;
  final int offsetMinutes;

  const TimezoneInfo(this.displayName, this.identifier, this.offsetMinutes);

  String get offsetString {
    final hours = offsetMinutes ~/ 60;
    final minutes = offsetMinutes.abs() % 60;
    final sign = offsetMinutes >= 0 ? '+' : '-';

    if (minutes == 0) {
      return 'UTC$sign${hours.abs()}';
    }
    return 'UTC$sign${hours.abs()}:${minutes.toString().padLeft(2, '0')}';
  }
}
