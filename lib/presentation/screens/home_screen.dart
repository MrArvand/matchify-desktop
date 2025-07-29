import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchify_desktop/presentation/widgets/file_upload_section.dart';
import 'package:matchify_desktop/presentation/widgets/matching_results_section.dart';
import 'package:matchify_desktop/presentation/widgets/export_section.dart';
import 'package:matchify_desktop/presentation/widgets/combination_selection_section.dart';
import 'package:matchify_desktop/core/theme/app_theme.dart';
import 'package:matchify_desktop/presentation/providers/matching_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchingProvider);
    final theme = Theme.of(context);

    // Auto-navigate based on current step
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tabController.index != state.currentStep) {
        _tabController.animateTo(state.currentStep);
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'مچیفای دسکتاپ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          onTap: (index) {
            ref.read(matchingProvider.notifier).setCurrentStep(index);
          },
          tabs: const [
            Tab(icon: Icon(Icons.upload_file), text: 'آپلود فایل‌ها'),
            Tab(icon: Icon(Icons.analytics), text: 'نتایج تطبیق'),
            Tab(icon: Icon(Icons.checklist), text: 'انتخاب ترکیب‌ها'),
            Tab(icon: Icon(Icons.download), text: 'خروجی'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FileUploadSection(),
          MatchingResultsSection(),
          CombinationSelectionSection(),
          ExportSection(),
        ],
      ),
    );
  }
}
