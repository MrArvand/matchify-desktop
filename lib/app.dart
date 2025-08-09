import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchify_desktop/presentation/screens/main_wrapper.dart';
import 'package:matchify_desktop/core/theme/app_theme.dart';
import 'package:matchify_desktop/presentation/providers/theme_provider.dart';

class MatchifyApp extends ConsumerWidget {
  const MatchifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return MaterialApp(
      title: 'مچیفای دسکتاپ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.effectiveThemeMode == AppThemeMode.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // RTL for Persian
          child: child!,
        );
      },
      home: const MainWrapper(),
    );
  }
}
