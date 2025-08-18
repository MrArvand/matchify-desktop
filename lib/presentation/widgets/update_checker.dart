import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchify_desktop/presentation/providers/auto_update_provider.dart';
import 'package:matchify_desktop/core/services/auto_update_service.dart';
import 'package:matchify_desktop/core/theme/app_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateChecker extends ConsumerStatefulWidget {
  const UpdateChecker({super.key});

  @override
  ConsumerState<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends ConsumerState<UpdateChecker> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = packageInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(autoUpdateProvider);
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.system_update,
                    color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'بررسی به‌روزرسانی',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_packageInfo != null)
                  Text(
                    'نسخه فعلی: ${_packageInfo!.version}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Configuration Check
            if (!AutoUpdateService.isConfigured) ...[
              _buildConfigurationWarning(theme),
              const SizedBox(height: 20),
            ],

            // Current Status
            if (state.isChecking) ...[
              _buildStatusCard(
                'در حال بررسی به‌روزرسانی...',
                Icons.search,
                AppTheme.infoColor,
                theme,
              ),
            ] else if (state.isDownloading) ...[
              _buildStatusCard(
                'در حال دانلود به‌روزرسانی...',
                Icons.download,
                AppTheme.accentColor,
                theme,
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: state.downloadProgress,
                backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
            ] else if (state.isInstalling) ...[
              _buildStatusCard(
                'در حال نصب به‌روزرسانی...',
                Icons.install_desktop,
                AppTheme.successColor,
                theme,
              ),
            ] else if (state.availableUpdate != null) ...[
              _buildUpdateAvailableCard(state.availableUpdate!, theme),
            ] else if (AutoUpdateService.isConfigured) ...[
              _buildStatusCard(
                'نسخه شما به‌روز است',
                Icons.check_circle,
                AppTheme.successColor,
                theme,
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                if (AutoUpdateService.isConfigured &&
                    state.availableUpdate == null &&
                    !state.isChecking &&
                    !state.isDownloading &&
                    !state.isInstalling)
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(autoUpdateProvider.notifier).checkForUpdates(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('بررسی به‌روزرسانی'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (state.availableUpdate != null &&
                    !state.isDownloading &&
                    !state.isInstalling) ...[
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(autoUpdateProvider.notifier).downloadUpdate(),
                    icon: const Icon(Icons.download),
                    label: const Text('دانلود و نصب'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => ref
                        .read(autoUpdateProvider.notifier)
                        .openReleasesPage(),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('مشاهده جزئیات'),
                  ),
                ],
                const Spacer(),
                if (AutoUpdateService.isConfigured)
                  OutlinedButton.icon(
                    onPressed: () => ref
                        .read(autoUpdateProvider.notifier)
                        .openReleasesPage(),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('صفحه انتشارات'),
                  ),
              ],
            ),

            // Error Display
            if (state.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: AppTheme.errorColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          ref.read(autoUpdateProvider.notifier).clearError(),
                      icon: const Icon(Icons.close),
                      color: AppTheme.errorColor,
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
      String message, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateAvailableCard(UpdateInfo updateInfo, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.new_releases, color: AppTheme.accentColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'نسخه جدید در دسترس است!',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'نسخه ${updateInfo.version}',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (updateInfo.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'تغییرات:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              updateInfo.releaseNotes,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 4),
              Text(
                'تاریخ انتشار: ${_formatDate(updateInfo.releaseDate)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.storage,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 4),
              Text(
                'حجم: ${AutoUpdateService.formatFileSize(updateInfo.fileSize)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildConfigurationWarning(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: AppTheme.warningColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'تنظیمات به‌روزرسانی ناقص است',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'برای استفاده از سیستم به‌روزرسانی خودکار، لطفاً اطلاعات مخزن GitHub را در فایل `auto_update_service.dart` تنظیم کنید.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.warningColor,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showConfigurationInstructions(context),
            icon: const Icon(Icons.help_outline),
            label: const Text('نمایش راهنمای تنظیمات'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.warningColor,
              side: BorderSide(color: AppTheme.warningColor.withOpacity(0.5)),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfigurationInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('راهنمای تنظیمات'),
        content: SingleChildScrollView(
          child: SelectableText(
            AutoUpdateService.configurationInstructions,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }
}
