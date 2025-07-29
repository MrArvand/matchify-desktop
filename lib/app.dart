import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchify_desktop/presentation/screens/home_screen.dart';
import 'package:matchify_desktop/core/theme/app_theme.dart';

class MatchifyApp extends StatelessWidget {
  const MatchifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مچیفای دسکتاپ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // RTL for Persian
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}
