import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:matchify_desktop/presentation/providers/matching_provider.dart';
import 'package:matchify_desktop/core/theme/app_theme.dart';
import 'package:matchify_desktop/core/services/print_service.dart';
import 'package:matchify_desktop/core/services/matching_service.dart';
import 'package:matchify_desktop/core/utils/persian_number_formatter.dart';
import 'package:matchify_desktop/core/models/matching_result.dart';
import 'package:matchify_desktop/core/constants/app_constants.dart';

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
          
          // System Terminal Sum Matches (if any)
          if (state.result?.systemTerminalSumMatches.isNotEmpty == true) ...[
            _buildSystemTerminalSumMatches(state, theme),
            const SizedBox(height: 32),
          ],
          const SizedBox(height: 32),

          // Terminal Code Summaries (if terminal codes are defined)
          if (state.receivablesTerminalCodeColumn != null) ...[
            _buildTerminalSummaries(state, theme),
            const SizedBox(height: 32),
          ],

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
                return sum + match.options[match.selectedOptionIndex].totalAmount;
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

    // Pre-calc
    final selectedCombinations = result.combinationMatches
        .where((match) => match.selectedOptionIndex >= 0)
        .toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'جزئیات کامل نتایج',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            if (result.exactMatches.isNotEmpty) ...[
              _buildSectionHeader('تطبیق‌های دقیق', Icons.check_circle,
                  AppTheme.successColor, theme),
              const SizedBox(height: 12),
              ...result.exactMatches
                  .map((match) => _buildExactMatchItem(match, state, theme)),
              const SizedBox(height: 20),
            ],

            if (selectedCombinations.isNotEmpty) ...[
              _buildSectionHeader('تطبیق‌های ترکیبی', Icons.merge_type,
                  AppTheme.accentColor, theme),
              const SizedBox(height: 12),
              ...selectedCombinations
                  .map((match) => _buildCombinationMatchItem(match, state, theme)),
              const SizedBox(height: 20),
            ],

            if (result.unmatchedPayments.isNotEmpty) ...[
              _buildSectionHeader('${AppConstants.varangarShortName} نامطابق',
                  Icons.warning, AppTheme.warningColor, theme),
              const SizedBox(height: 12),
              ...result.unmatchedPayments.map((payment) => _buildUnmatchedItem(
                    'ردیف ${PersianNumberFormatter.formatNumber(payment.rowNumber)}',
                    PersianNumberFormatter.formatCurrency(payment.amount),
                    AppConstants.varangarShortName,
                    state,
                    theme,
                    isPayment: true,
                    rowNumber: payment.rowNumber,
                  )),
              const SizedBox(height: 20),
            ],

            if (result.unmatchedReceivables.isNotEmpty) ...[
              _buildSectionHeader('${AppConstants.bankShortName} نامطابق',
                  Icons.warning, AppTheme.warningColor, theme),
              const SizedBox(height: 12),
              ...result.unmatchedReceivables.map((receivable) => _buildUnmatchedItem(
                    'ردیف ${PersianNumberFormatter.formatNumber(receivable.rowNumber)}',
                    PersianNumberFormatter.formatCurrency(receivable.amount),
                    AppConstants.bankShortName,
                    state,
                    theme,
                    isPayment: false,
                    rowNumber: receivable.rowNumber,
                  )),
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

  Widget _buildExactMatchItem(
      ExactMatch match, MatchingState state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'تطبیق دقیق',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
              const Spacer(),
              Text(
                PersianNumberFormatter.formatCurrency(match.amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildRowWithExtras(
                  title:
                      '${AppConstants.varangarShortName}: ردیف ${PersianNumberFormatter.formatNumber(match.payment.rowNumber)}',
                  amount:
                      'مبلغ: ${PersianNumberFormatter.formatCurrency(match.payment.amount)}',
                  isPayment: true,
                  rowNumber: match.payment.rowNumber,
                  state: state,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRowWithExtras(
                  title:
                      '${AppConstants.bankShortName}: ردیف ${PersianNumberFormatter.formatNumber(match.receivable.rowNumber)}',
                  amount:
                      'مبلغ: ${PersianNumberFormatter.formatCurrency(match.receivable.amount)}',
                  isPayment: false,
                  rowNumber: match.receivable.rowNumber,
                  state: state,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCombinationMatchItem(
      CombinationMatch match, MatchingState state, ThemeData theme) {
    final selectedOption = match.options[match.selectedOptionIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.merge_type, color: AppTheme.accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'تطبیق ترکیبی',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
              const Spacer(),
              Text(
                PersianNumberFormatter.formatCurrency(
                    selectedOption.totalAmount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Payment row + extras
          _buildRowWithExtras(
            title:
                '${AppConstants.varangarShortName}: ردیف ${PersianNumberFormatter.formatNumber(match.payment.rowNumber)}',
            amount:
                'مبلغ: ${PersianNumberFormatter.formatCurrency(match.payment.amount)}',
            isPayment: true,
            rowNumber: match.payment.rowNumber,
            state: state,
            theme: theme,
          ),
          const SizedBox(height: 8),

          // Receivables combination
          Text(
            'ترکیب انتخاب شده (${PersianNumberFormatter.formatNumber(selectedOption.receivables.length)} ${AppConstants.bankShortName}):',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...selectedOption.receivables.map((receivable) => Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
                ),
                child: _buildRowWithExtras(
                  title:
                      'ردیف ${PersianNumberFormatter.formatNumber(receivable.rowNumber)}',
                  amount:
                      PersianNumberFormatter.formatCurrency(receivable.amount),
                  isPayment: false,
                  rowNumber: receivable.rowNumber,
                  state: state,
                  theme: theme,
                  inline: true,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildUnmatchedItem(String rowInfo, String amount, String type,
      MatchingState state, ThemeData theme,
      {required bool isPayment, required int rowNumber}) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppTheme.warningColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$rowInfo ($type)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                _buildExtraColumnsRow(
                  isPayment: isPayment,
                  rowNumber: rowNumber,
                  state: state,
                  theme: theme,
                ),
                Text(
                  'نامطابق',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.warningColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.warningColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowWithExtras({
    required String title,
    required String amount,
    required bool isPayment,
    required int rowNumber,
    required MatchingState state,
    required ThemeData theme,
    bool inline = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          amount,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        _buildExtraColumnsRow(
          isPayment: isPayment,
          rowNumber: rowNumber,
          state: state,
          theme: theme,
          inline: inline,
        ),
      ],
    );
  }

  Widget _buildExtraColumnsRow({
    required bool isPayment,
    required int rowNumber,
    required MatchingState state,
    required ThemeData theme,
    bool inline = false,
  }) {
    // Selected columns and headers
    final selected = isPayment
        ? state.paymentsSelectedColumns
        : state.receivablesSelectedColumns;
    final headers = isPayment ? state.paymentsHeaders : state.receivablesHeaders;

    if (selected.isEmpty || headers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find record additionalData
    final record = isPayment
        ? state.payments.firstWhere(
            (r) => r.rowNumber == rowNumber,
            orElse: () => state.payments.first,
          )
        : state.receivables.firstWhere(
            (r) => r.rowNumber == rowNumber,
            orElse: () => state.receivables.first,
          );

    final chips = selected.map((colIndex) {
      // amount column excluded upstream
      final key = 'col_$colIndex';
      final value = record.additionalData[key]?.toString() ?? '-';
      final labelIdx = PersianNumberFormatter.formatNumber(colIndex + 1);
      final labelHeader = colIndex < headers.length ? headers[colIndex] : '';
      return Chip(
        label: Text('$labelIdx: $labelHeader = $value'),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: chips,
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
      final state = ref.read(matchingProvider);
      await PrintService.printReport(
        result: result,
        payments: state.payments,
        receivables: state.receivables,
        paymentsSelectedColumns: state.paymentsSelectedColumns,
        receivablesSelectedColumns: state.receivablesSelectedColumns,
        paymentsHeaders: state.paymentsHeaders,
        receivablesHeaders: state.receivablesHeaders,
        receivablesTerminalCodeColumn: state.receivablesTerminalCodeColumn,
      );

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
      final report = _generateReportText(result, ref);
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

  String _generateReportText(MatchingResult result, WidgetRef ref) {
    final state = ref.read(matchingProvider);
    final buffer = StringBuffer();

    buffer.writeln('گزارش کامل تطبیق مبالغ');
    buffer.writeln('=' * 60);
    buffer.writeln('تاریخ: ${DateTime.now().toLocal()}');
    buffer.writeln(
        'زمان پردازش: ${PersianNumberFormatter.formatNumber(result.processingTime.inMilliseconds)} میلی‌ثانیه');
    buffer.writeln();

    // Exact Matches - Detailed
    if (result.exactMatches.isNotEmpty) {
      buffer.writeln('تطبیق‌های دقیق:');
      buffer.writeln('=' * 30);
      for (final match in result.exactMatches) {
        buffer.writeln(
            '• ردیف ${AppConstants.varangarShortName} ${PersianNumberFormatter.formatNumber(match.payment.rowNumber)}');
        buffer.writeln(
            '  مبلغ ${AppConstants.varangarShortName}: ${PersianNumberFormatter.formatCurrency(match.payment.amount)}');
        buffer.writeln(
            '• ردیف ${AppConstants.bankShortName} ${PersianNumberFormatter.formatNumber(match.receivable.rowNumber)}');
        buffer.writeln(
            '  مبلغ ${AppConstants.bankShortName}: ${PersianNumberFormatter.formatCurrency(match.receivable.amount)}');
        buffer.writeln(
            '• تطبیق: ${PersianNumberFormatter.formatCurrency(match.amount)}');
        buffer.writeln();
      }
    }

    // Combination Matches - Detailed
    final selectedCombinations = result.combinationMatches
        .where((match) => match.selectedOptionIndex >= 0)
        .toList();
    if (selectedCombinations.isNotEmpty) {
      buffer.writeln('تطبیق‌های ترکیبی:');
      buffer.writeln('=' * 30);
      for (final match in selectedCombinations) {
        final selectedOption = match.options[match.selectedOptionIndex];
        buffer.writeln(
            '• ردیف ${AppConstants.varangarShortName} ${PersianNumberFormatter.formatNumber(match.payment.rowNumber)}');
        buffer.writeln(
            '  مبلغ ${AppConstants.varangarShortName}: ${PersianNumberFormatter.formatCurrency(match.payment.amount)}');
        buffer.writeln(
            '• ترکیب انتخاب شده (${PersianNumberFormatter.formatNumber(selectedOption.receivables.length)} ${AppConstants.bankShortName}):');
        for (final receivable in selectedOption.receivables) {
          buffer.writeln(
              '  - ردیف ${PersianNumberFormatter.formatNumber(receivable.rowNumber)}: ${PersianNumberFormatter.formatCurrency(receivable.amount)}');
        }
        buffer.writeln(
            '• مجموع ترکیب: ${PersianNumberFormatter.formatCurrency(selectedOption.totalAmount)}');
        buffer.writeln();
      }
    }

    // Unmatched Payments - Detailed
    if (result.unmatchedPayments.isNotEmpty) {
      buffer.writeln('${AppConstants.varangarShortName} نامطابق:');
      buffer.writeln('=' * 30);
      for (final payment in result.unmatchedPayments) {
        buffer.writeln(
            '• ردیف ${PersianNumberFormatter.formatNumber(payment.rowNumber)}: ${PersianNumberFormatter.formatCurrency(payment.amount)}');
      }
      buffer.writeln();
    }

    // Unmatched Receivables - Detailed
    if (result.unmatchedReceivables.isNotEmpty) {
      buffer.writeln('${AppConstants.bankShortName} نامطابق:');
      buffer.writeln('=' * 30);
      for (final receivable in result.unmatchedReceivables) {
        buffer.writeln(
            '• ردیف ${PersianNumberFormatter.formatNumber(receivable.rowNumber)}: ${PersianNumberFormatter.formatCurrency(receivable.amount)}');
      }
      buffer.writeln();
    }

    // Summary
    buffer.writeln('خلاصه نهایی:');
    buffer.writeln('=' * 30);
    buffer.writeln(
        'تطبیق‌های دقیق: ${PersianNumberFormatter.formatNumber(result.totalExactMatches)}');
    buffer.writeln(
        'تطبیق‌های ترکیبی: ${PersianNumberFormatter.formatNumber(selectedCombinations.length)}');
    buffer.writeln(
        '${AppConstants.varangarShortName} نامطابق: ${PersianNumberFormatter.formatNumber(result.totalUnmatchedPayments)}');
    buffer.writeln(
        '${AppConstants.bankShortName} نامطابق: ${PersianNumberFormatter.formatNumber(result.totalUnmatchedReceivables)}');
    buffer.writeln(
        'مجموع مبالغ تطابق‌شده: ${PersianNumberFormatter.formatCurrency(result.totalMatchedAmount)}');

    // Terminal Code Summaries (if terminal codes are defined)
    if (state.receivablesTerminalCodeColumn != null) {
      final terminalSummaries =
          MatchingService.calculateTerminalSummaries(state.receivables);
      if (terminalSummaries.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('خلاصه کدهای ترمینال:');
        buffer.writeln('=' * 30);
        for (final entry in terminalSummaries.entries) {
          final terminalCode = entry.key;
          final totalAmount = entry.value;
          buffer.writeln(
              'کد ترمینال $terminalCode: ${PersianNumberFormatter.formatCurrency(totalAmount)}');
        }
      }
    }

    return buffer.toString();
  }

  Widget _buildSystemTerminalSumMatches(MatchingState state, ThemeData theme) {
    final systemMatches = state.result!.systemTerminalSumMatches;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تطبیق‌های خودکار کدهای ترمینال',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'تطبیق‌های خودکار که توسط سیستم انجام شده است',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: systemMatches.map((match) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ردیف ورانگر: ${match.payment.rowNumber}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'کد ترمینال: ${match.terminalCode}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            'ردیف‌های بانک: ${match.receivableRows.join(', ')}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      MatchingService.formatAmount(match.amount),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTerminalSummaries(MatchingState state, ThemeData theme) {
    // Calculate terminal summaries from all receivables
    final terminalSummaries =
        MatchingService.calculateTerminalSummaries(state.receivables);

    if (terminalSummaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'خلاصه کدهای ترمینال',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'مجموع مبالغ هر کد ترمینال',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: terminalSummaries.entries.map((entry) {
              final terminalCode = entry.key;
              final totalAmount = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'کد ترمینال: $terminalCode',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      MatchingService.formatAmount(totalAmount),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
