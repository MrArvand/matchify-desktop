import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchify_desktop/presentation/providers/theme_provider.dart';
import 'package:matchify_desktop/core/theme/app_theme.dart';

class ThemeSwitch extends ConsumerWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final theme = Theme.of(context);

    return PopupMenuButton<AppThemeMode>(
      icon: Icon(
        _getThemeIcon(themeMode),
        color: theme.colorScheme.onSurface,
      ),
      tooltip: 'تغییر تم',
      onSelected: (AppThemeMode mode) {
        themeNotifier.setThemeMode(mode);
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<AppThemeMode>(
          value: AppThemeMode.system,
          child: Row(
            children: [
              Icon(
                Icons.brightness_auto,
                color: themeMode == AppThemeMode.system
                    ? AppTheme.primaryColor
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'سیستم',
                style: TextStyle(
                  color: themeMode == AppThemeMode.system
                      ? AppTheme.primaryColor
                      : theme.colorScheme.onSurface,
                  fontWeight: themeMode == AppThemeMode.system
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<AppThemeMode>(
          value: AppThemeMode.light,
          child: Row(
            children: [
              Icon(
                Icons.light_mode,
                color: themeMode == AppThemeMode.light
                    ? AppTheme.primaryColor
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'روشن',
                style: TextStyle(
                  color: themeMode == AppThemeMode.light
                      ? AppTheme.primaryColor
                      : theme.colorScheme.onSurface,
                  fontWeight: themeMode == AppThemeMode.light
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<AppThemeMode>(
          value: AppThemeMode.dark,
          child: Row(
            children: [
              Icon(
                Icons.dark_mode,
                color: themeMode == AppThemeMode.dark
                    ? AppTheme.primaryColor
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'تاریک',
                style: TextStyle(
                  color: themeMode == AppThemeMode.dark
                      ? AppTheme.primaryColor
                      : theme.colorScheme.onSurface,
                  fontWeight: themeMode == AppThemeMode.dark
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
    }
  }
}
