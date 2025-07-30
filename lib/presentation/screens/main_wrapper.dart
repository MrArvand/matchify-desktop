import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:matchify_desktop/core/constants/app_constants.dart';
import 'package:matchify_desktop/presentation/screens/getting_started_screen.dart';
import 'package:matchify_desktop/presentation/screens/home_screen.dart';

class MainWrapper extends ConsumerStatefulWidget {
  const MainWrapper({super.key});

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  @override
  Widget build(BuildContext context) {
    // Always show getting started page first
    return const GettingStartedScreen();
  }
}
