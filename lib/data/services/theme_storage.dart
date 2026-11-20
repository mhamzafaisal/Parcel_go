import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'theme_mode';

ThemeMode themeModeFromString(String? v) {
  switch (v) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

String themeModeToString(ThemeMode m) {
  switch (m) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

String themeModeLabel(ThemeMode m) {
  switch (m) {
    case ThemeMode.light:
      return 'Light';
    case ThemeMode.dark:
      return 'Dark';
    case ThemeMode.system:
      return 'System default';
  }
}

class ThemeStorage {
  static Future<ThemeMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    return themeModeFromString(prefs.getString(_key));
  }

  static Future<void> save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, themeModeToString(mode));
  }
}
