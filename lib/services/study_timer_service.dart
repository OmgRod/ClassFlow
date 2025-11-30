import 'package:flutter/foundation.dart';
import 'dart:async';

/// Service for study timer with Pomodoro technique support
class StudyTimerService extends ChangeNotifier {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  Duration _sessionDuration = const Duration(minutes: 25);
  Duration _breakDuration = const Duration(minutes: 5);
  Duration _longBreakDuration = const Duration(minutes: 15);

  bool _isRunning = false;
  bool _isBreak = false;
  int _completedSessions = 0;
  int _subjectId;

  TimerMode _mode = TimerMode.pomodoro;
  DateTime? _startTime;

  StudyTimerService({int? subjectId}) : _subjectId = subjectId ?? 0;

  // Getters
  Duration get elapsed => _elapsed;
  Duration get sessionDuration => _sessionDuration;
  Duration get breakDuration => _breakDuration;
  Duration get longBreakDuration => _longBreakDuration;
  Duration get remaining => _isBreak
      ? (_completedSessions % 4 == 0 ? _longBreakDuration : _breakDuration) -
            _elapsed
      : _sessionDuration - _elapsed;

  bool get isRunning => _isRunning;
  bool get isBreak => _isBreak;
  int get completedSessions => _completedSessions;
  int get subjectId => _subjectId;
  TimerMode get mode => _mode;
  DateTime? get startTime => _startTime;

  double get progress {
    final total = _isBreak
        ? (_completedSessions % 4 == 0 ? _longBreakDuration : _breakDuration)
        : _sessionDuration;
    return _elapsed.inSeconds / total.inSeconds;
  }

  /// Start the timer
  void start() {
    if (_isRunning) return;

    _isRunning = true;
    _startTime = DateTime.now().subtract(_elapsed);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsed += const Duration(seconds: 1);

      // Check if session/break is complete
      if (_isBreak) {
        final breakDur = _completedSessions % 4 == 0
            ? _longBreakDuration
            : _breakDuration;
        if (_elapsed >= breakDur) {
          _completeBreak();
        }
      } else {
        if (_elapsed >= _sessionDuration) {
          _completeSession();
        }
      }

      notifyListeners();
    });

    notifyListeners();
  }

  /// Pause the timer
  void pause() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  /// Resume the timer
  void resume() {
    start();
  }

  /// Reset the timer
  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _elapsed = Duration.zero;
    _isBreak = false;
    _startTime = null;
    notifyListeners();
  }

  /// Skip to next phase (session/break)
  void skip() {
    if (_isBreak) {
      _completeBreak();
    } else {
      _completeSession();
    }
  }

  /// Complete current session and start break
  void _completeSession() {
    _completedSessions++;
    _isBreak = true;
    _elapsed = Duration.zero;
    _startTime = DateTime.now();
    // Notification or sound would go here
    notifyListeners();
  }

  /// Complete break and start new session
  void _completeBreak() {
    _isBreak = false;
    _elapsed = Duration.zero;
    _startTime = DateTime.now();
    notifyListeners();
  }

  /// Set session duration
  void setSessionDuration(Duration duration) {
    _sessionDuration = duration;
    notifyListeners();
  }

  /// Set break duration
  void setBreakDuration(Duration duration) {
    _breakDuration = duration;
    notifyListeners();
  }

  /// Set long break duration
  void setLongBreakDuration(Duration duration) {
    _longBreakDuration = duration;
    notifyListeners();
  }

  /// Set timer mode
  void setMode(TimerMode mode) {
    _mode = mode;
    notifyListeners();
  }

  /// Set subject being studied
  void setSubject(int subjectId) {
    _subjectId = subjectId;
    notifyListeners();
  }

  /// Get formatted time string (MM:SS)
  String getFormattedTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Get formatted remaining time
  String get formattedRemaining => getFormattedTime(remaining);

  /// Get formatted elapsed time
  String get formattedElapsed => getFormattedTime(_elapsed);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

enum TimerMode {
  pomodoro, // 25 min work, 5 min break, 15 min long break after 4 sessions
  custom, // User-defined durations
  stopwatch, // Simple count-up timer
}
