import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:matchify_desktop/presentation/providers/matching_provider.dart';
import 'package:matchify_desktop/core/services/excel_service.dart';
import 'package:matchify_desktop/core/theme/app_theme.dart';
import 'package:matchify_desktop/core/utils/persian_number_formatter.dart';
import 'package:matchify_desktop/core/constants/app_constants.dart';
import 'package:matchify_desktop/presentation/widgets/loading_dialog.dart';

class FileUploadSection extends ConsumerStatefulWidget {
  const FileUploadSection({super.key});

  @override
  ConsumerState<FileUploadSection> createState() => _FileUploadSectionState();
}

class _FileUploadSectionState extends ConsumerState<FileUploadSection> {
  List<String> paymentsHeaders = [];
  List<String> receivablesHeaders = [];
  bool isLoadingHeaders = false;
  bool isShowingLoadingDialog = false;
  int? receivablesTerminalCodeColumn;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchingProvider);
    final notifier = ref.read(matchingProvider.notifier);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'آپلود فایل‌های اکسل',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'فایل‌های خروجی فاکتورهای ورانگر و تراکنش های بانک را انتخاب کنید تا تطبیق شروع شود',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),

          // File Selection Cards
          Row(
            children: [
              Expanded(
                child: _buildFileCard(
                  title: AppConstants.varangarFileTitle,
                  subtitle: AppConstants.varangarFileSubtitle,
                  filePath: state.paymentsFilePath,
                  headers: paymentsHeaders,
                  onFileSelected: (path) async {
                    notifier.setPaymentsFile(path);
                    await _loadHeaders(path, true);
                    // Automatically load data when file is selected
                    if (state.paymentsAmountColumn >= 0) {
                      await notifier.loadPaymentsFile();
                    }
                  },
                  amountColumn: state.paymentsAmountColumn,
                  onColumnChanged: (columnIndex) async {
                    notifier.setPaymentsAmountColumn(columnIndex);
                    // Automatically load data when column is selected
                    if (state.paymentsFilePath != null && columnIndex != null) {
                      await notifier.loadPaymentsFile();
                    }
                  },
                  isLoading: false, // Hide loading
                  progress: state.progress,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildFileCard(
                  title: AppConstants.bankFileTitle,
                  subtitle: AppConstants.bankFileSubtitle,
                  filePath: state.receivablesFilePath,
                  headers: receivablesHeaders,
                  onFileSelected: (path) async {
                    notifier.setReceivablesFile(path);
                    await _loadHeaders(path, false);
                    // Automatically load data when file is selected
                    if (state.receivablesAmountColumn >= 0) {
                      await notifier.loadReceivablesFile();
                    }
                  },
                  amountColumn: state.receivablesAmountColumn,
                  onColumnChanged: (columnIndex) async {
                    notifier.setReceivablesAmountColumn(columnIndex);
                    // Automatically load data when column is selected
                    if (state.receivablesFilePath != null &&
                        columnIndex != null) {
                      await notifier.loadReceivablesFile();
                    }
                  },
                  terminalCodeColumn: state.receivablesTerminalCodeColumn,
                  onTerminalCodeColumnChanged: (columnIndex) async {
                    notifier.setReceivablesTerminalCodeColumn(columnIndex);
                    if (state.receivablesFilePath != null) {
                      await notifier.loadReceivablesFile();
                    }
                  },
                  isLoading: false, // Hide loading
                  progress: state.progress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Action Buttons
          _buildActionButtons(state, notifier),

          // Loading Dialog
          if (isShowingLoadingDialog)
            LoadingDialog(
              title: 'در حال پردازش',
              message: 'در حال یافتن ترکیب‌های ممکن...',
              progress: state.progress,
            ),
          const SizedBox(height: 24),

          // Error Display
          if (state.error != null) _buildErrorCard(state.error!),
        ],
      ),
    );
  }

  Widget _buildFileCard({
    required String title,
    required String subtitle,
    String? filePath,
    required List<String> headers,
    required Function(String) onFileSelected,
    required int amountColumn,
    required Function(int?) onColumnChanged,
    int? terminalCodeColumn,
    Function(int?)? onTerminalCodeColumnChanged,
    required bool isLoading,
    required double progress,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.description,
                      color: AppTheme.primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // File Selection
            ElevatedButton.icon(
              onPressed: isLoading ? null : () => _pickFile(onFileSelected),
              icon: const Icon(Icons.upload_file),
              label: Text(filePath == null ? 'انتخاب فایل' : 'تغییر فایل'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // File Path Display
            if (filePath != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.file_present,
                      color: AppTheme.accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        filePath.split('/').last,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Column Selection (Amount)
            if (headers.isNotEmpty) ...[
              Text(
                'ستون مبلغ را انتخاب کنید:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: amountColumn < headers.length ? amountColumn : null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                items: headers.asMap().entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                        '${PersianNumberFormatter.formatNumber(entry.key + 1)}: ${entry.value}'),
                  );
                }).toList(),
                onChanged: onColumnChanged,
              ),
              const SizedBox(height: 16),
              // Terminal Code Selection (optional)
              if (onTerminalCodeColumnChanged != null) ...[
                Text(
                  'ستون کد ترمینال (اختیاری):',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: terminalCodeColumn != null &&
                          terminalCodeColumn < headers.length
                      ? terminalCodeColumn
                      : null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  items: headers.asMap().entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                          '${PersianNumberFormatter.formatNumber(entry.key + 1)}: ${entry.value}'),
                    );
                  }).toList(),
                  onChanged: onTerminalCodeColumnChanged,
                ),
                const SizedBox(height: 16),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(MatchingState state, MatchingNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: state.payments.isNotEmpty &&
                    state.receivables.isNotEmpty &&
                    !state.isLoading
                ? () async {
                    setState(() {
                      isShowingLoadingDialog = true;
                    });
                    await notifier.performMatching();
                    if (mounted) {
                      setState(() {
                        isShowingLoadingDialog = false;
                      });
                    }
                  }
                : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('شروع تطبیق'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: state.isLoading ? null : () => notifier.reset(),
          icon: const Icon(Icons.refresh),
          label: const Text('بازنشانی'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String error) {
    final theme = Theme.of(context);

    return Card(
      color: AppTheme.errorColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.errorColor,
                ),
              ),
            ),
            IconButton(
              onPressed: () => ref.read(matchingProvider.notifier).clearError(),
              icon: const Icon(Icons.close),
              color: AppTheme.errorColor,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile(Function(String) onFileSelected) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          onFileSelected(filePath);
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadHeaders(String filePath, bool isPayments) async {
    setState(() {
      isLoadingHeaders = true;
    });

    try {
      final headers = await ExcelService.getColumnHeaders(filePath);
      setState(() {
        if (isPayments) {
          paymentsHeaders = headers;
        } else {
          receivablesHeaders = headers;
        }
        isLoadingHeaders = false;
      });
    } catch (e) {
      setState(() {
        isLoadingHeaders = false;
      });
    }
  }
}
