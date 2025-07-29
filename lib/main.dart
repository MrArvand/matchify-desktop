import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchify_desktop/app.dart';
import 'package:matchify_desktop/core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.settingsBox);
  await Hive.openBox(AppConstants.matchesBox);

  runApp(const ProviderScope(child: MatchifyApp()));
}
