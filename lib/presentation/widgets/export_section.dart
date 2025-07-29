import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:matchify_desktop/presentation/providers/matching_provider.dart';
import 'package:matchify_desktop/core/theme/app_theme.dart';
import 'package:matchify_desktop/core/services/print_service.dart';
import 'package:matchify_desktop/core/utils/persian_number_formatter.dart';
import 'package:matchify_desktop/core/models/matching_result.dart';

class ExportSection extends ConsumerWidget {
  const ExportSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchingProvider);
    final theme = Theme.of(context);

    if (state.result == null) {
      return _buildEmptyState(context, theme);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'خروجی نتایج',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'نتایج تطبیق را به صورت فایل اکسل ذخیره کنید یا چاپ کنید',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),

          // Summary Cards
          _buildSummaryCards(state, theme),
          const SizedBox(height: 32),

          // Export Options
          _buildExportOptions(state, ref, theme),
          const SizedBox(height: 32),

          // Results Preview
          _buildResultsPreview(state, theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.download,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'هنوز نتیجه‌ای برای خروجی وجود ندارد',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابتدا فایل‌ها را آپلود کرده و تطبیق را انجام دهید',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(MatchingState state, ThemeData theme) {
    final result = state.result!;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'تطبیق‌های دقیق',
            count: result.totalExactMatches,
            amount: result.exactMatches
                .fold(0.0, (sum, match) => sum + match.amount),
            icon: Icons.check_circle,
            color: AppTheme.successColor,
            theme: theme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'تطبیق‌های ترکیبی',
            count: result.totalCombinationMatches,
            amount: result.combinationMatches.fold(0.0, (sum, match) {
              if (match.selectedOptionIndex >= 0) {
                return sum +
                    match.options[match.selectedOptionIndex].totalAmount;
              }
              return sum;
            }),
            icon: Icons.merge_type,
            color: AppTheme.accentColor,
            theme: theme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'نامطابق‌ها',
            count: result.totalUnmatchedPayments +
                result.totalUnmatchedReceivables,
            amount: result.unmatchedPayments
                    .fold(0.0, (sum, payment) => sum + payment.amount) +
                result.unmatchedReceivables
                    .fold(0.0, (sum, receivable) => sum + receivable.amount),
            icon: Icons.warning,
            color: AppTheme.warningColor,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required double amount,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              PersianNumberFormatter.formatNumber(count),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              PersianNumberFormatter.formatCurrency(amount),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptions(
      MatchingState state, WidgetRef ref, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'گزینه‌های خروجی',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        state.isLoading ? null : () => _exportToExcel(ref),
                    icon: const Icon(Icons.file_download),
                    label: const Text('ذخیره به اکسل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.isLoading
                        ? null
                        : () => _printReport(state.result!, ref),
                    icon: const Icon(Icons.print),
                    label: const Text('چاپ گزارش'),
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
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => _copyToClipboard(state.result!, ref),
              icon: const Icon(Icons.copy),
              label: const Text('کپی به کلیپ‌بورد'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsPreview(MatchingState state, ThemeData theme) {
    final result = state.result!;

    // Pre-calculate the variables outside the Column's children list
    final selectedCombinations = result.combinationMatches
        .where((match) => match.selectedOptionIndex >= 0)
        .toList();
    final totalUnmatched =
        result.totalUnmatchedPayments + result.totalUnmatchedReceivables;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'پیش‌نمایش نتایج',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Exact Matches
            if (result.exactMatches.isNotEmpty) ...[
              _buildSectionHeader('تطبیق‌های دقیق', Icons.check_circle,
                  AppTheme.successColor, theme),
              const SizedBox(height: 12),
              ...result.exactMatches.take(3).map((match) => _buildMatchItem(
                    'ردیف ${PersianNumberFormatter.formatNumber(match.payment.rowNumber)} → ردیف ${PersianNumberFormatter.formatNumber(match.receivable.rowNumber)}',
                    PersianNumberFormatter.formatCurrency(match.amount),
                    theme,
                  )),
              if (result.exactMatches.length > 3)
                Text(
                  'و ${PersianNumberFormatter.formatNumber(result.exactMatches.length - 3)} مورد دیگر...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              const SizedBox(height: 20),
            ],

            // Combination Matches
            if (selectedCombinations.isNotEmpty) ...[
              _buildSectionHeader('تطبیق‌های ترکیبی', Icons.merge_type,
                  AppTheme.accentColor, theme),
              const SizedBox(height: 12),
              ...selectedCombinations.take(3).map((match) {
                final selectedOption = match.options[match.selectedOptionIndex];
                return _buildMatchItem(
                  'ردیف ${PersianNumberFormatter.formatNumber(match.payment.rowNumber)} (${PersianNumberFormatter.formatNumber(selectedOption.receivables.length)} ترکیب)',
                  PersianNumberFormatter.formatCurrency(
                      selectedOption.totalAmount),
                  theme,
                );
              }),
              if (selectedCombinations.length > 3)
                Text(
                  'و ${PersianNumberFormatter.formatNumber(selectedCombinations.length - 3)} مورد دیگر...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              const SizedBox(height: 20),
            ],

            // Unmatched
            if (totalUnmatched > 0) ...[
              _buildSectionHeader(
                  'نامطابق‌ها', Icons.warning, AppTheme.warningColor, theme),
              const SizedBox(height: 12),
              Text(
                '${PersianNumberFormatter.formatNumber(result.totalUnmatchedPayments)} پرداخت و ${PersianNumberFormatter.formatNumber(result.totalUnmatchedReceivables)} دریافت نامطابق',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, IconData icon, Color color, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchItem(String description, String amount, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              description,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            amount,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToExcel(WidgetRef ref) async {
    try {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'ذخیره فایل اکسل',
        fileName:
            'matching_results_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        allowedExtensions: ['xlsx'],
      );

      if (outputPath != null) {
        await ref.read(matchingProvider.notifier).exportResults(outputPath);

        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text(
              'نتایج با موفقیت به: ${outputPath.split('/').last} ذخیره شد',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('خطا در ذخیره کردن نتایج: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _printReport(MatchingResult result, WidgetRef ref) async {
    try {
      await PrintService.printReport(result);

      ScaffoldMessenger.of(ref.context).showSnackBar(
        const SnackBar(
          content: Text('گزارش برای چاپ آماده شد'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('خطا در چاپ گزارش: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _copyToClipboard(MatchingResult result, WidgetRef ref) async {
    try {
      final report = _generateReportText(result);
      await Clipboard.setData(ClipboardData(text: report));

      ScaffoldMessenger.of(ref.context).showSnackBar(
        const SnackBar(
          content: Text('گزارش در کلیپ‌بورد کپی شد'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('خطا در کپی کردن گزارش: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  String _generateReportText(MatchingResult result) {
    final buffer = StringBuffer();

    buffer.writeln('گزارش تطبیق مبالغ');
    buffer.writeln('=' * 50);
    buffer.writeln('تاریخ: ${DateTime.now().toLocal()}');
    buffer.writeln(
        'زمان پردازش: ${PersianNumberFormatter.formatNumber(result.processingTime.inMilliseconds)} میلی‌ثانیه');
    buffer.writeln();

    // Exact Matches
    buffer.writeln('تطبیق‌های دقیق:');
    buffer.writeln('-' * 30);
    for (final match in result.exactMatches) {
      buffer.writeln(
          'ردیف پرداخت ${PersianNumberFormatter.formatNumber(match.payment.rowNumber)} → ردیف دریافت ${PersianNumberFormatter.formatNumber(match.receivable.rowNumber)}');
      buffer.writeln(
          'مبلغ: ${PersianNumberFormatter.formatCurrency(match.amount)}');
      buffer.writeln();
    }

    // Combination Matches
    if (result.combinationMatches.isNotEmpty) {
      buffer.writeln('تطبیق‌های ترکیبی:');
      buffer.writeln('-' * 30);
      for (final match in result.combinationMatches) {
        if (match.selectedOptionIndex >= 0) {
          final selectedOption = match.options[match.selectedOptionIndex];
          buffer.writeln(
              'ردیف پرداخت ${PersianNumberFormatter.formatNumber(match.payment.rowNumber)}:');
          buffer.writeln(
              'مبلغ پرداخت: ${PersianNumberFormatter.formatCurrency(match.payment.amount)}');
          buffer.writeln('ترکیب انتخاب شده:');
          for (final receivable in selectedOption.receivables) {
            buffer.writeln(
                '  - ردیف ${PersianNumberFormatter.formatNumber(receivable.rowNumber)}: ${PersianNumberFormatter.formatCurrency(receivable.amount)}');
          }
          buffer.writeln(
              'مجموع: ${PersianNumberFormatter.formatCurrency(selectedOption.totalAmount)}');
          buffer.writeln();
        }
      }
    }

    // Unmatched Payments
    if (result.unmatchedPayments.isNotEmpty) {
      buffer.writeln('پرداخت‌های نامطابق:');
      buffer.writeln('-' * 30);
      for (final payment in result.unmatchedPayments) {
        buffer.writeln(
            'ردیف ${PersianNumberFormatter.formatNumber(payment.rowNumber)}: ${PersianNumberFormatter.formatCurrency(payment.amount)}');
      }
      buffer.writeln();
    }

    // Unmatched Receivables
    if (result.unmatchedReceivables.isNotEmpty) {
      buffer.writeln('دریافت‌های نامطابق:');
      buffer.writeln('-' * 30);
      for (final receivable in result.unmatchedReceivables) {
        buffer.writeln(
            'ردیف ${PersianNumberFormatter.formatNumber(receivable.rowNumber)}: ${PersianNumberFormatter.formatCurrency(receivable.amount)}');
      }
      buffer.writeln();
    }

    // Summary
    buffer.writeln('خلاصه:');
    buffer.writeln('-' * 30);
    buffer.writeln(
        'تطبیق‌های دقیق: ${PersianNumberFormatter.formatNumber(result.totalExactMatches)}');
    buffer.writeln(
        'تطبیق‌های ترکیبی: ${PersianNumberFormatter.formatNumber(result.totalCombinationMatches)}');
    buffer.writeln(
        'پرداخت‌های نامطابق: ${PersianNumberFormatter.formatNumber(result.totalUnmatchedPayments)}');
    buffer.writeln(
        'دریافت‌های نامطابق: ${PersianNumberFormatter.formatNumber(result.totalUnmatchedReceivables)}');
    buffer.writeln(
        'مجموع مبالغ تطابق‌شده: ${PersianNumberFormatter.formatCurrency(result.totalMatchedAmount)}');

    return buffer.toString();
  }
}
