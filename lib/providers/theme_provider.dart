import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Theme mode options
enum ThemeModeOption {
  system,
  light,
  dark;

  String get label {
    switch (this) {
      case ThemeModeOption.system:
        return 'System';
      case ThemeModeOption.light:
        return 'Light';
      case ThemeModeOption.dark:
        return 'Dark';
    }
  }

  String get labelEn {
    switch (this) {
      case ThemeModeOption.system:
        return 'System';
      case ThemeModeOption.light:
        return 'Light';
      case ThemeModeOption.dark:
        return 'Dark';
    }
  }
}

/// ThemeProvider manages the app's theme mode preference
class ThemeNotifier extends StateNotifier<ThemeModeOption> {
  ThemeNotifier() : super(ThemeModeOption.system) {
    _loadTheme();
  }

  static const String _prefKey = AppConstants.prefThemeMode;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_prefKey);
    if (savedTheme != null) {
      state = ThemeModeOption.values.firstWhere(
        (e) => e.name == savedTheme,
        orElse: () => ThemeModeOption.system,
      );
    }
  }

  /// Set theme mode and persist the choice
  Future<void> setTheme(ThemeModeOption mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
    state = mode;
  }

  /// Toggle between light and dark (cycles through options)
  Future<void> toggleTheme() async {
    final next = switch (state) {
      ThemeModeOption.system || ThemeModeOption.light => ThemeModeOption.dark,
      ThemeModeOption.dark => ThemeModeOption.light,
    };
    await setTheme(next);
  }
}

/// Riverpod provider for theme mode
final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeModeOption>(
  (ref) => ThemeNotifier(),
);

/// Provider that resolves the actual Flutter ThemeMode from the option
final resolvedThemeModeProvider = Provider<ThemeMode>((ref) {
  final modeOption = ref.watch(themeModeProvider);
  return switch (modeOption) {
    ThemeModeOption.system => ThemeMode.system,
    ThemeModeOption.light => ThemeMode.light,
    ThemeModeOption.dark => ThemeMode.dark,
  };
});
