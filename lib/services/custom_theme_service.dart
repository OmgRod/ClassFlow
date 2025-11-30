import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Service for managing custom themes
class CustomThemeService extends ChangeNotifier {
  static const String _boxName = 'theme_settings';
  late Box _box;

  // Current theme settings
  Color _primaryColor = const Color(0xFF6200EE);
  Color _secondaryColor = const Color(0xFF03DAC6);
  bool _useDynamicColors = false;

  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  bool get useDynamicColors => _useDynamicColors;

  /// Initialize the service
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _loadSettings();
  }

  /// Load saved theme settings
  void _loadSettings() {
    _primaryColor = Color(_box.get('primary_color', defaultValue: 0xFF6200EE));
    _secondaryColor = Color(
      _box.get('secondary_color', defaultValue: 0xFF03DAC6),
    );
    _useDynamicColors = _box.get('use_dynamic_colors', defaultValue: false);
    notifyListeners();
  }

  /// Set primary color
  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    await _box.put('primary_color', color.toARGB32());
    notifyListeners();
  }

  /// Set secondary color
  Future<void> setSecondaryColor(Color color) async {
    _secondaryColor = color;
    await _box.put('secondary_color', color.toARGB32());
    notifyListeners();
  }

  /// Toggle dynamic colors (Material You)
  Future<void> setUseDynamicColors(bool value) async {
    _useDynamicColors = value;
    await _box.put('use_dynamic_colors', value);
    notifyListeners();
  }

  /// Get light theme with custom colors
  ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        secondary: _secondaryColor,
        brightness: Brightness.light,
      ),
    );
  }

  /// Get dark theme with custom colors
  ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        secondary: _secondaryColor,
        brightness: Brightness.dark,
      ),
    );
  }

  /// Reset to default theme colors
  Future<void> resetToDefaults() async {
    _primaryColor = const Color(0xFF6200EE);
    _secondaryColor = const Color(0xFF03DAC6);
    _useDynamicColors = false;
    await _box.put('primary_color', _primaryColor.toARGB32());
    await _box.put('secondary_color', _secondaryColor.toARGB32());
    await _box.put('use_dynamic_colors', false);
    notifyListeners();
  }

  /// Predefined theme presets
  static const List<ThemePreset> presets = [
    ThemePreset('Default Purple', Color(0xFF6200EE), Color(0xFF03DAC6)),
    ThemePreset('Ocean Blue', Color(0xFF0277BD), Color(0xFF00ACC1)),
    ThemePreset('Forest Green', Color(0xFF2E7D32), Color(0xFF66BB6A)),
    ThemePreset('Sunset Orange', Color(0xFFE64A19), Color(0xFFFF9800)),
    ThemePreset('Royal Red', Color(0xFFC62828), Color(0xFFEF5350)),
    ThemePreset('Lavender', Color(0xFF7E57C2), Color(0xFFBA68C8)),
    ThemePreset('Teal', Color(0xFF00897B), Color(0xFF26A69A)),
    ThemePreset('Deep Pink', Color(0xFFC2185B), Color(0xFFEC407A)),
  ];

  /// Apply a preset theme
  Future<void> applyPreset(ThemePreset preset) async {
    await setPrimaryColor(preset.primary);
    await setSecondaryColor(preset.secondary);
  }
}

/// Theme preset model
class ThemePreset {
  final String name;
  final Color primary;
  final Color secondary;

  const ThemePreset(this.name, this.primary, this.secondary);
}
