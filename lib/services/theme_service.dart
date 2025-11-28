import 'package:flutter/material.dart';
import 'database_service.dart';

class ThemeService extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeService() {
    final modeStr = DatabaseService.settings['themeMode'] as String?;
    switch (modeStr) {
      case 'light':
        _mode = ThemeMode.light;
        break;
      case 'dark':
        _mode = ThemeMode.dark;
        break;
      default:
        _mode = ThemeMode.system;
    }
  }

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    if (mode == ThemeMode.light) {
      DatabaseService.settings['themeMode'] = 'light';
    } else if (mode == ThemeMode.dark) {
      DatabaseService.settings['themeMode'] = 'dark';
    } else {
      DatabaseService.settings['themeMode'] = 'system';
    }
    await DatabaseService.save();
    notifyListeners();
  }
}
