import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/theme_storage.dart';

/// main() mein disk se padh kar yahan daala jata hai
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ThemeStorage.save(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
