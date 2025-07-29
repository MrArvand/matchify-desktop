import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchify_desktop/presentation/providers/matching_provider.dart';
import 'package:matchify_desktop/core/services/matching_service.dart';
import 'package:matchify_desktop/core/theme/app_theme.dart';
import 'package:matchify_desktop/core/models/matching_result.dart';

class MatchingResultsSection extends ConsumerWidget {
  const MatchingResultsSection({super.key});

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
            'نتایج تطبیق',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تحلیل در ${state.result!.processingTime.inMilliseconds} میلی‌ثانیه تکمیل شد',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),

          // Statistics Cards
          _buildStatisticsCards(state.result!, theme),
          const SizedBox(height: 32),

          // Exact Matches
          if (state.result!.exactMatches.isNotEmpty) ...[
            _buildExactMatchesSection(state.result!, theme),
            const SizedBox(height: 24),
          ],

          // Combination Matches
          if (state.result!.combinationMatches.isNotEmpty) ...[
            _buildCombinationMatchesSection(state.result!, theme),
            const SizedBox(height: 24),
          ],

          // Unmatched Records
          _buildUnmatchedSection(state.result!, theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'هنوز نتیجه‌ای وجود ندارد',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'فایل‌ها را آپلود کرده و تطبیق را شروع کنید تا نتایج را اینجا ببینید',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(MatchingResult result, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'تطبیق‌های دقیق',
            value: result.totalExactMatches.toString(),
            icon: Icons.check_circle,
            color: AppTheme.accentColor,
            theme: theme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'تطبیق‌های ترکیبی',
            value: result.totalCombinationMatches.toString(),
            icon: Icons.link,
            color: AppTheme.secondaryColor,
            theme: theme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'پرداخت‌های نامطابق',
            value: result.totalUnmatchedPayments.toString(),
            icon: Icons.warning,
            color: AppTheme.warningColor,
            theme: theme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'دریافت‌های نامطابق',
            value: result.totalUnmatchedReceivables.toString(),
            icon: Icons.warning,
            color: AppTheme.warningColor,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExactMatchesSection(MatchingResult result, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.accentColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'تطبیق‌های دقیق (${result.exactMatches.length})',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ردیف پرداخت')),
                  DataColumn(label: Text('مبلغ پرداخت')),
                  DataColumn(label: Text('ردیف دریافت')),
                  DataColumn(label: Text('مبلغ دریافت')),
                ],
                rows: result.exactMatches.map((match) {
                  return DataRow(
                    cells: [
                      DataCell(Text(match.payment.rowNumber.toString())),
                      DataCell(
                        Text(
                          MatchingService.formatAmount(match.payment.amount),
                        ),
                      ),
                      DataCell(Text(match.receivable.rowNumber.toString())),
                      DataCell(
                        Text(
                          MatchingService.formatAmount(match.receivable.amount),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinationMatchesSection(
    MatchingResult result,
    ThemeData theme,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: AppTheme.secondaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'تطبیق‌های ترکیبی (${result.combinationMatches.length})',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...result.combinationMatches.map((match) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ردیف پرداخت ${match.payment.rowNumber}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            MatchingService.formatAmount(match.payment.amount),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Show selected combination if available
                      if (match.selectedOptionIndex >= 0) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.accentColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ترکیب انتخاب شده:',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ...match.selectedReceivables.map((receivable) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(left: 16, top: 4),
                                  child: Row(
                                    children: [
                                      Text('ردیف ${receivable.rowNumber}:'),
                                      const SizedBox(width: 8),
                                      Text(
                                        MatchingService.formatAmount(
                                            receivable.amount),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: AppTheme.accentColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ] else ...[
                        Text(
                          '${match.options.length} گزینه ترکیب موجود',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لطفاً به بخش "انتخاب ترکیب‌ها" بروید تا ترکیب مورد نظر خود را انتخاب کنید',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUnmatchedSection(MatchingResult result, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: AppTheme.warningColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'پرداخت‌های نامطابق (${result.unmatchedPayments.length})',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (result.unmatchedPayments.isNotEmpty)
                    ...result.unmatchedPayments.take(10).map((payment) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text('ردیف ${payment.rowNumber}:'),
                            const SizedBox(width: 8),
                            Text(
                              MatchingService.formatAmount(payment.amount),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.warningColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                  else
                    Text(
                      'پرداختی نامطابق وجود ندارد',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: AppTheme.warningColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'دریافت‌های نامطابق (${result.unmatchedReceivables.length})',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (result.unmatchedReceivables.isNotEmpty)
                    ...result.unmatchedReceivables.take(10).map((receivable) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text('ردیف ${receivable.rowNumber}:'),
                            const SizedBox(width: 8),
                            Text(
                              MatchingService.formatAmount(receivable.amount),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.warningColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                  else
                    Text(
                      'دریافتی نامطابق وجود ندارد',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
