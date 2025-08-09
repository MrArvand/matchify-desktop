import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:matchify_desktop/core/constants/app_constants.dart';

enum AppThemeMode {
  system,
  light,
  dark,
}

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.system) {
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final settingsBox = Hive.box(AppConstants.settingsBox);
    final savedMode = settingsBox.get('themeMode', defaultValue: 'system');
    state = AppThemeMode.values.firstWhere(
      (mode) => mode.name == savedMode,
      orElse: () => AppThemeMode.system,
    );
  }

  void setThemeMode(AppThemeMode mode) {
    state = mode;
    final settingsBox = Hive.box(AppConstants.settingsBox);
    settingsBox.put('themeMode', mode.name);
  }

  void toggleTheme() {
    switch (state) {
      case AppThemeMode.system:
        setThemeMode(AppThemeMode.light);
        break;
      case AppThemeMode.light:
        setThemeMode(AppThemeMode.dark);
        break;
      case AppThemeMode.dark:
        setThemeMode(AppThemeMode.system);
        break;
    }
  }

  AppThemeMode get effectiveThemeMode {
    if (state == AppThemeMode.system) {
      // Get system theme mode
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark
          ? AppThemeMode.dark
          : AppThemeMode.light;
    }
    return state;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>(
  (ref) => ThemeNotifier(),
);
