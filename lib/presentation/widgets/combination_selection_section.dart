import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchify_desktop/presentation/providers/matching_provider.dart';
import 'package:matchify_desktop/core/models/matching_result.dart';
import 'package:matchify_desktop/core/theme/app_theme.dart';
import 'package:matchify_desktop/core/services/matching_service.dart';

class CombinationSelectionSection extends ConsumerWidget {
  const CombinationSelectionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchingProvider);
    final theme = Theme.of(context);

    if (state.result == null || state.result!.combinationMatches.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'انتخاب تطبیق‌های ترکیبی',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'برای هر پرداخت، ترکیب مورد نظر خود را انتخاب کنید',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),

          // Combination Selection Cards
          ...state.result!.combinationMatches
              .map((match) => _buildCombinationCard(match, ref, theme)),

          const SizedBox(height: 32),

          // Action Buttons
          _buildActionButtons(state, ref, theme),
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
            Icons.check_circle_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'هیچ تطبیق ترکیبی وجود ندارد',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تمام تطبیق‌ها دقیق هستند یا هیچ تطبیق ترکیبی یافت نشد',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinationCard(
    CombinationMatch match,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Info
            Row(
              children: [
                Icon(Icons.payment, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ردیف پرداخت ${match.payment.rowNumber}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'مبلغ: ${match.payment.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Options
            Text(
              'گزینه‌های ترکیب (${match.options.length} گزینه):',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            ...match.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = match.selectedOptionIndex == index;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.accentColor
                        : theme.colorScheme.outline,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected
                      ? AppTheme.accentColor.withOpacity(0.1)
                      : theme.colorScheme.surface,
                ),
                child: RadioListTile<int>(
                  value: index,
                  groupValue: match.selectedOptionIndex,
                  onChanged: (value) {
                    ref.read(matchingProvider.notifier).selectCombinationOption(
                          match.payment.rowNumber,
                          value!,
                        );
                  },
                  title: Text(
                    'ترکیب ${index + 1}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مجموع: ${option.totalAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: option.receivables.map((receivable) {
                          return Chip(
                            label: Text(
                              'ردیف ${receivable.rowNumber}: ${receivable.amount.toStringAsFixed(2)}',
                            ),
                            backgroundColor:
                                AppTheme.secondaryColor.withOpacity(0.2),
                            labelStyle: theme.textTheme.bodySmall,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  activeColor: AppTheme.accentColor,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    MatchingState state,
    WidgetRef ref,
    ThemeData theme,
  ) {
    final hasUnselectedCombinations = state.result!.combinationMatches
        .any((match) => match.selectedOptionIndex == -1);

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: hasUnselectedCombinations
                ? null
                : () {
                    ref.read(matchingProvider.notifier).finalizeSelections();
                  },
            icon: const Icon(Icons.check),
            label: const Text('تأیید انتخاب‌ها'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () {
            ref.read(matchingProvider.notifier).resetSelections();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('بازنشانی انتخاب‌ها'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
