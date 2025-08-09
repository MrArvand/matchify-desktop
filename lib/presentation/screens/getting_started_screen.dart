import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:matchify_desktop/core/constants/app_constants.dart';
import 'package:matchify_desktop/core/theme/app_theme.dart';
import 'package:matchify_desktop/presentation/widgets/theme_switch.dart';
import 'package:matchify_desktop/presentation/screens/home_screen.dart';

class GettingStartedScreen extends ConsumerWidget {
  const GettingStartedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: Navigator.of(context).canPop()
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
              ),
              actions: const [
                ThemeSwitch(),
                SizedBox(width: 8),
              ],
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: const [
                ThemeSwitch(),
                SizedBox(width: 8),
              ],
            ),
      body: Column(
        children: [
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 80,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'به مچیفای دسکتاپ خوش آمدید',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'راهنمای استفاده از نرم‌افزار تطبیق فاکتورهای ورانگر و تراکنش های بانک',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Guide sections
                  _buildGuideSection(
                    context,
                    theme,
                    'مرحله اول: آپلود فایل‌ها',
                    'فایل‌های اکسل حاوی خروجی فاکتورهای ورانگر و خروجی تراکنش های بانک را آپلود کنید. نرم‌افزار از فرمت‌های .xlsx و .xls پشتیبانی می‌کند.',
                    Icons.upload_file,
                    AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 24),

                  _buildGuideSection(
                    context,
                    theme,
                    'مرحله دوم: تحلیل و تطبیق',
                    'نرم‌افزار به طور خودکار فاکتورهای ورانگر و تراکنش های بانک را بر اساس مبلغ تطبیق می‌دهد. تطبیق‌های دقیق و ترکیبی شناسایی می‌شوند.',
                    Icons.analytics,
                    AppTheme.accentColor,
                  ),
                  const SizedBox(height: 24),

                  _buildGuideSection(
                    context,
                    theme,
                    'مرحله سوم: انتخاب ترکیب‌ها',
                    'برای تطبیق‌های ترکیبی، می‌توانید ترکیب مورد نظر خود را از بین گزینه‌های موجود انتخاب کنید.',
                    Icons.checklist,
                    AppTheme.secondaryColor,
                  ),
                  const SizedBox(height: 24),

                  _buildGuideSection(
                    context,
                    theme,
                    'مرحله چهارم: خروجی',
                    'نتایج نهایی را به صورت فایل اکسل یا PDF ذخیره کنید و گزارش‌های مورد نیاز را تهیه کنید.',
                    Icons.download,
                    AppTheme.warningColor,
                  ),
                  const SizedBox(height: 32),

                  // Tips section
                  _buildTipsSection(context, theme),
                  const SizedBox(height: 32),

                  // Start button
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _startApplication(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow),
                          const SizedBox(width: 8),
                          Text(
                            'شروع کار',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Copyright sticky bar
          _buildCopyrightBar(context, theme),
        ],
      ),
    );
  }

  Widget _buildGuideSection(
    BuildContext context,
    ThemeData theme,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text(
                  'نکات مهم',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              context,
              theme,
              'فایل‌های اکسل باید دارای ستون‌های مبلغ باشند',
            ),
            _buildTipItem(
              context,
              theme,
              'حداکثر ۱۰,۰۰۰ رکورد در هر فایل قابل پردازش است',
            ),
            _buildTipItem(
              context,
              theme,
              'زمان پردازش به تعداد رکوردها بستگی دارد',
            ),
            _buildTipItem(
              context,
              theme,
              'نتایج را قبل از خروجی نهایی بررسی کنید',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyrightBar(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/img/rabin.png',
            height: 20,
            width: 20,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Text(
            'طراحی و توسعه: رابین سامانه پارس',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _startApplication(BuildContext context, WidgetRef ref) async {
    // Mark that user has seen the getting started page
    final settingsBox = Hive.box(AppConstants.settingsBox);
    await settingsBox.put('hasSeenGettingStarted', true);

    // Always navigate to home screen
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }
}
