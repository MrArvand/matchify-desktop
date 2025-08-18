import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchify_desktop/presentation/providers/matching_provider.dart';
import 'package:matchify_desktop/core/models/matching_result.dart';
import 'package:matchify_desktop/core/constants/app_constants.dart';
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
            'برای هر ${AppConstants.varangarShortName}، ترکیب مورد نظر خود را انتخاب کنید',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),

          // Hint Section
          _buildHintSection(theme),

          const SizedBox(height: 24),

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
    final state = ref.watch(matchingProvider);
    
    // Debug: Print combination match info
    print(
        'DEBUG UI: Building combination card for payment ${match.payment.rowNumber}');
    print('DEBUG UI: isTerminalBased: ${match.isTerminalBased}');
    print('DEBUG UI: options count: ${match.options.length}');
    for (final option in match.options) {
      print(
          'DEBUG UI: Option isTerminalBased: ${option.isTerminalBased}, terminalCode: ${option.terminalCode}');
    }
    
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
                        'ردیف ${AppConstants.varangarShortName} ${match.payment.rowNumber}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'مبلغ: ${MatchingService.formatAmount(match.payment.amount)}',
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
            Row(
              children: [
                Text(
                  'گزینه‌های ترکیب (${match.options.length} گزینه):',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (match.options.isEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: AppTheme.warningColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      'تمام گزینه‌ها به دلیل تداخل حذف شدند',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            ...match.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = match.selectedOptionIndex == index;

              // Get all selected receivable rows from other matches
              final selectedReceivableRows = <int>{};
              for (final otherMatch in state.result!.combinationMatches) {
                if (otherMatch.payment.rowNumber != match.payment.rowNumber &&
                    otherMatch.selectedOptionIndex >= 0) {
                  final selectedOption =
                      otherMatch.options[otherMatch.selectedOptionIndex];
                  for (final receivable in selectedOption.receivables) {
                    selectedReceivableRows.add(receivable.rowNumber);
                  }
                }
              }

              // Check which receivable rows in this option are already used
              final usedReceivableRows = <int>{};
              for (final receivable in option.receivables) {
                if (selectedReceivableRows.contains(receivable.rowNumber)) {
                  usedReceivableRows.add(receivable.rowNumber);
                }
              }

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
                  title: Row(
                    children: [
                      Text(
                        option.isTerminalBased
                            ? 'ترکیب ${index + 1}'
                            : 'ترکیب ${index + 1}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Terminal type badge
                      if (option.isTerminalBased) ...[
                        _buildTerminalTypeBadge(option, theme),
                        const SizedBox(width: 8),
                      ],
                      // Item count badge
                      _buildItemCountBadge(option, theme),
                      const SizedBox(width: 8),
                      // Terminal code badge for each option
                      if (state.receivablesTerminalCodeColumn != null) ...[
                        _buildOptionTerminalBadge(option, theme),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show total amount and terminal information
                      Row(
                        children: [
                          Text(
                            'مجموع: ${MatchingService.formatAmount(option.totalAmount)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (state.receivablesTerminalCodeColumn != null) ...[
                            const SizedBox(width: 16),
                            _buildTerminalSumInfo(option, theme),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: option.receivables.map((receivable) {
                          final isUsed =
                              usedReceivableRows.contains(receivable.rowNumber);
                          final terminal =
                              receivable.additionalData['terminal_code'];
                          return Chip(
                            label: Text(
                              terminal != null && terminal.toString().isNotEmpty
                                  ? 'ردیف ${receivable.rowNumber} | ترمینال $terminal: ${MatchingService.formatAmount(receivable.amount)}'
                                  : 'ردیف ${receivable.rowNumber}: ${MatchingService.formatAmount(receivable.amount)}',
                            ),
                            backgroundColor: isUsed
                                ? AppTheme.warningColor.withOpacity(0.2)
                                : AppTheme.secondaryColor.withOpacity(0.2),
                            labelStyle: theme.textTheme.bodySmall?.copyWith(
                              color: isUsed ? AppTheme.warningColor : null,
                            ),
                          );
                        }).toList(),
                      ),
                      if (usedReceivableRows.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'ردیف‌های ${usedReceivableRows.join(', ')} قبلاً انتخاب شده‌اند',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.warningColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
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
    // Check if all combinations with options have valid selections
    bool canSubmit = true;
    String? submitError;

    // Get combinations that have options (not empty due to conflicts)
    final combinationsWithOptions = state.result!.combinationMatches
        .where((match) => match.options.isNotEmpty)
        .toList();

    if (combinationsWithOptions.isEmpty) {
      // All combinations were removed due to conflicts
      canSubmit = false;
      submitError =
          'تمام ترکیب‌ها به دلیل تداخل با انتخاب‌های قبلی حذف شده‌اند';
    } else {
      // Check if all combinations with options have selections
      for (final match in combinationsWithOptions) {
        if (match.selectedOptionIndex == -1) {
          canSubmit = false;
          submitError = 'لطفاً برای تمام ترکیب‌های موجود گزینه‌ای انتخاب کنید';
          break;
        }
      }
    }

    return Column(
      children: [
        if (submitError != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    submitError,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Show summary of what will be finalized
        if (canSubmit) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'خلاصه انتخاب‌ها:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${state.result!.combinationMatches.where((match) => match.options.isNotEmpty && match.selectedOptionIndex >= 0).length} ترکیب انتخاب شده',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.accentColor.withOpacity(0.8),
                        ),
                      ),
                      if (state.result!.combinationMatches.any((match) =>
                          match.options.isNotEmpty &&
                          match.selectedOptionIndex == -1)) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${state.result!.combinationMatches.where((match) => match.options.isNotEmpty && match.selectedOptionIndex == -1).length} ترکیب انتخاب نشده',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.warningColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (state.result!.combinationMatches
                          .any((match) => match.options.isEmpty)) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${state.result!.combinationMatches.where((match) => match.options.isEmpty).length} ترکیب به دلیل تداخل حذف خواهد شد',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.warningColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canSubmit
                    ? () {
                        ref
                            .read(matchingProvider.notifier)
                            .finalizeSelections();
                      }
                    : null,
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
        ),
      ],
    );
  }

  /// Build terminal code badge for combination options
  Widget _buildTerminalCodeBadge(CombinationMatch match, ThemeData theme) {
    // Check if all options have the same terminal code
    final allTerminalCodes = <String>{};
    for (final option in match.options) {
      for (final receivable in option.receivables) {
        final terminalCode =
            receivable.additionalData['terminal_code']?.toString();
        if (terminalCode != null && terminalCode.isNotEmpty) {
          allTerminalCodes.add(terminalCode);
        }
      }
    }

    if (allTerminalCodes.isEmpty) {
      return const SizedBox.shrink();
    }

    final isSingleTerminal = allTerminalCodes.length == 1;
    final badgeColor =
        isSingleTerminal ? AppTheme.accentColor : AppTheme.secondaryColor;
    final badgeText = isSingleTerminal
        ? 'ترمینال واحد: ${allTerminalCodes.first}'
        : 'ترمینال‌های متعدد: ${allTerminalCodes.length}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSingleTerminal ? Icons.link : Icons.link_off,
            size: 16,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build terminal badge for individual combination options
  Widget _buildOptionTerminalBadge(CombinationOption option, ThemeData theme) {
    if (option.isTerminalBased) {
      // Terminal-based combination
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_tree,
              size: 14,
              color: AppTheme.accentColor,
            ),
            const SizedBox(width: 4),
            Text(
              'ترمینال ${option.terminalCode ?? ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      // Regular combination - check if all receivables are from same terminal
      final terminalCodes = <String>{};
      for (final receivable in option.receivables) {
        final terminalCode =
            receivable.additionalData['terminal_code']?.toString();
        if (terminalCode != null && terminalCode.isNotEmpty) {
          terminalCodes.add(terminalCode);
        }
      }

      if (terminalCodes.isEmpty) {
        return const SizedBox.shrink();
      }

      final isSingleTerminal = terminalCodes.length == 1;
      final badgeColor =
          isSingleTerminal ? AppTheme.accentColor : AppTheme.secondaryColor;
      final badgeText = isSingleTerminal ? 'ترمینال واحد' : 'ترمینال‌های متعدد';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: badgeColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSingleTerminal ? Icons.link : Icons.link_off,
              size: 14,
              color: badgeColor,
            ),
            const SizedBox(width: 4),
            Text(
              badgeText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Build terminal sum information for combination options
  Widget _buildTerminalSumInfo(CombinationOption option, ThemeData theme) {
    if (option.isTerminalBased) {
      // For terminal-based combinations, show the terminal code and sum
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_tree,
              size: 14,
              color: AppTheme.accentColor,
            ),
            const SizedBox(width: 4),
            Text(
              'ترمینال ${option.terminalCode ?? ''}: ${MatchingService.formatAmount(option.totalAmount)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      // For regular combinations, group by terminal and show sums
      final terminalSums = <String, int>{};
      for (final receivable in option.receivables) {
        final terminalCode =
            receivable.additionalData['terminal_code']?.toString() ??
                'بدون ترمینال';
        terminalSums[terminalCode] =
            (terminalSums[terminalCode] ?? 0) + receivable.amount;
      }

      if (terminalSums.isEmpty) {
        return const SizedBox.shrink();
      }

      // Show terminal sums
      return Wrap(
        spacing: 8,
        children: terminalSums.entries.map((entry) {
          final terminalCode = entry.key;
          final sum = entry.value;
          final isNoTerminal = terminalCode == 'بدون ترمینال';
          final color =
              isNoTerminal ? AppTheme.secondaryColor : AppTheme.accentColor;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isNoTerminal ? Icons.block : Icons.account_tree,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  '$terminalCode: ${MatchingService.formatAmount(sum)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }
  }

  /// Build item count badge for combination options
  Widget _buildItemCountBadge(CombinationOption option, ThemeData theme) {
    final itemCount = option.receivables.length;
    final badgeColor = AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.list_alt,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$itemCount آیتم',
            style: theme.textTheme.bodySmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build terminal type badge for terminal-based combinations
  Widget _buildTerminalTypeBadge(CombinationOption option, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_tree,
            size: 14,
            color: AppTheme.accentColor,
          ),
          const SizedBox(width: 4),
          Text(
            'ترکیب ترمینال',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build hint section explaining badges and combinations
  Widget _buildHintSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'راهنمای ترکیب‌ها و نشانه‌ها',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Badge explanations
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildBadgeExplanation(
                'ترکیب ترمینال',
                'ترکیب‌هایی که مجموع تمام ردیف‌های یک ترمینال با مبلغ وارنگار برابر است',
                AppTheme.accentColor,
                Icons.account_tree,
                theme,
              ),
              _buildBadgeExplanation(
                'X آیتم',
                'تعداد ردیف‌های بانکی که در این ترکیب قرار دارند',
                AppTheme.primaryColor,
                Icons.list_alt,
                theme,
              ),
              _buildBadgeExplanation(
                'ترمینال واحد',
                'تمام ردیف‌های این ترکیب از یک ترمینال هستند',
                AppTheme.accentColor,
                Icons.link,
                theme,
              ),
              _buildBadgeExplanation(
                'ترمینال‌های متعدد',
                'ردیف‌های این ترکیب از چندین ترمینال مختلف هستند',
                AppTheme.secondaryColor,
                Icons.link_off,
                theme,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Combination type explanations
          Text(
            'انواع ترکیب‌ها:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• ترکیب‌های ترمینال: این ترکیب‌ها اولویت بالاتری دارند و مجموع تمام ردیف‌های یک ترمینال را نشان می‌دهند\n'
            '• ترکیب‌های معمولی: ترکیب‌هایی که با الگوریتم‌های مختلف یافت شده‌اند\n'
            '• انتخاب یک ترکیب ترمینال باعث حذف تمام ردیف‌های آن ترمینال از سایر ترکیب‌ها می‌شود',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual badge explanation
  Widget _buildBadgeExplanation(
    String title,
    String description,
    Color color,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
