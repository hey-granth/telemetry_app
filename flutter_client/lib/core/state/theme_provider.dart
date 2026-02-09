/// Theme mode state management.
///
/// Manages user's theme preference with persistence.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themePreferenceKey = 'theme_mode';

/// Theme mode notifier with persistence
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themePreferenceKey);

      if (savedMode != null) {
        state = ThemeMode.values.firstWhere(
          (mode) => mode.name == savedMode,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      // If preferences fail, stay with system default
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, mode.name);
    } catch (e) {
      // Preferences save failed, but state is updated
    }
  }
}

/// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

