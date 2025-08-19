import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchify_desktop/core/models/record.dart';
import 'package:matchify_desktop/core/models/matching_result.dart';
import 'package:matchify_desktop/core/services/matching_service.dart';
import 'package:matchify_desktop/core/services/excel_service.dart';

class MatchingState {
  final bool isLoading;
  final double progress;
  final String? error;
  final List<PaymentRecord> payments;
  final List<ReceivableRecord> receivables;
  final MatchingResult? result;
  final List<CombinationMatch>? originalCombinationMatches; // Store original matches before selections
  final String? paymentsFilePath;
  final String? receivablesFilePath;
  final int paymentsAmountColumn;
  final int receivablesAmountColumn;
  final int? receivablesTerminalCodeColumn;
  final int currentStep; // 0: Upload, 1: Results, 2: Selection, 3: Export

  // New: Headers and display selections for UX-only export/print
  final List<String> paymentsHeaders;
  final List<String> receivablesHeaders;
  final List<int> paymentsSelectedColumns;
  final List<int> receivablesSelectedColumns;

  MatchingState({
    this.isLoading = false,
    this.progress = 0.0,
    this.error,
    this.payments = const [],
    this.receivables = const [],
    this.result,
    this.originalCombinationMatches,
    this.paymentsFilePath,
    this.receivablesFilePath,
    this.paymentsAmountColumn = 0,
    this.receivablesAmountColumn = 0,
    this.receivablesTerminalCodeColumn,
    this.currentStep = 0,
    this.paymentsHeaders = const [],
    this.receivablesHeaders = const [],
    this.paymentsSelectedColumns = const [],
    this.receivablesSelectedColumns = const [],
  });

  MatchingState copyWith({
    bool? isLoading,
    double? progress,
    String? error,
    List<PaymentRecord>? payments,
    List<ReceivableRecord>? receivables,
    MatchingResult? result,
    List<CombinationMatch>? originalCombinationMatches,
    String? paymentsFilePath,
    String? receivablesFilePath,
    int? paymentsAmountColumn,
    int? receivablesAmountColumn,
    int? receivablesTerminalCodeColumn,
    int? currentStep,
    List<String>? paymentsHeaders,
    List<String>? receivablesHeaders,
    List<int>? paymentsSelectedColumns,
    List<int>? receivablesSelectedColumns,
  }) {
    return MatchingState(
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      payments: payments ?? this.payments,
      receivables: receivables ?? this.receivables,
      result: result ?? this.result,
      originalCombinationMatches:
          originalCombinationMatches ?? this.originalCombinationMatches,
      paymentsFilePath: paymentsFilePath ?? this.paymentsFilePath,
      receivablesFilePath: receivablesFilePath ?? this.receivablesFilePath,
      paymentsAmountColumn: paymentsAmountColumn ?? this.paymentsAmountColumn,
      receivablesAmountColumn:
          receivablesAmountColumn ?? this.receivablesAmountColumn,
      receivablesTerminalCodeColumn:
          receivablesTerminalCodeColumn ?? this.receivablesTerminalCodeColumn,
      currentStep: currentStep ?? this.currentStep,
      paymentsHeaders: paymentsHeaders ?? this.paymentsHeaders,
      receivablesHeaders: receivablesHeaders ?? this.receivablesHeaders,
      paymentsSelectedColumns:
          paymentsSelectedColumns ?? this.paymentsSelectedColumns,
      receivablesSelectedColumns:
          receivablesSelectedColumns ?? this.receivablesSelectedColumns,
    );
  }
}

class MatchingNotifier extends StateNotifier<MatchingState> {
  MatchingNotifier() : super(MatchingState());

  void setPaymentsFile(String filePath) {
    state = state.copyWith(paymentsFilePath: filePath);
  }

  void setReceivablesFile(String filePath) {
    state = state.copyWith(receivablesFilePath: filePath);
  }

  void setPaymentsHeaders(List<String> headers) {
    state = state.copyWith(paymentsHeaders: headers);
  }

  void setReceivablesHeaders(List<String> headers) {
    state = state.copyWith(receivablesHeaders: headers);
  }

  void togglePaymentsDisplayColumn(int index) {
    final current = List<int>.from(state.paymentsSelectedColumns);
    if (current.contains(index)) {
      current.remove(index);
    } else {
      current.add(index);
    }
    state = state.copyWith(paymentsSelectedColumns: current);
  }

  void toggleReceivablesDisplayColumn(int index) {
    final current = List<int>.from(state.receivablesSelectedColumns);
    if (current.contains(index)) {
      current.remove(index);
    } else {
      current.add(index);
    }
    state = state.copyWith(receivablesSelectedColumns: current);
  }

  void setPaymentsAmountColumn(int? columnIndex) {
    if (columnIndex != null) {
      // Ensure amount column is not in display selections
      final filtered = state.paymentsSelectedColumns
          .where((i) => i != columnIndex)
          .toList();
      state = state.copyWith(
        paymentsAmountColumn: columnIndex,
        paymentsSelectedColumns: filtered,
      );
    }
  }

  void setReceivablesAmountColumn(int? columnIndex) {
    if (columnIndex != null) {
      final filtered = state.receivablesSelectedColumns
          .where((i) => i != columnIndex)
          .toList();
      state = state.copyWith(
        receivablesAmountColumn: columnIndex,
        receivablesSelectedColumns: filtered,
      );
    }
  }

  // Ref code column removed

  void setReceivablesTerminalCodeColumn(int? columnIndex) {
    // Always set terminal code column
    state = state.copyWith(receivablesTerminalCodeColumn: columnIndex);

    // Also pre-select it for display (UX), if provided
    if (columnIndex != null) {
      final current = List<int>.from(state.receivablesSelectedColumns);
      if (!current.contains(columnIndex)) {
        current.add(columnIndex);
        state = state.copyWith(receivablesSelectedColumns: current);
      }
    }
  }

  Future<void> loadPaymentsFile() async {
    if (state.paymentsFilePath == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final records = await ExcelService.readRecordsFromFile(
        filePath: state.paymentsFilePath!,
        amountColumnIndex: state.paymentsAmountColumn,
        startRow: 2, // Always start from row 2
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      final payments = records.map((r) => PaymentRecord.fromRecord(r)).toList();
      state = state.copyWith(
        payments: payments,
        isLoading: false,
        progress: 0.0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading payments file: $e',
        progress: 0.0,
      );
    }
  }

  Future<void> loadReceivablesFile() async {
    if (state.receivablesFilePath == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final records = await ExcelService.readRecordsFromFile(
        filePath: state.receivablesFilePath!,
        amountColumnIndex: state.receivablesAmountColumn,
        startRow: 2, // Always start from row 2
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
        terminalCodeColumnIndex: state.receivablesTerminalCodeColumn,
      );

      final receivables =
          records.map((r) => ReceivableRecord.fromRecord(r)).toList();
      state = state.copyWith(
        receivables: receivables,
        isLoading: false,
        progress: 0.0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading receivables file: $e',
        progress: 0.0,
      );
    }
  }

  Future<void> performMatching() async {
    if (state.payments.isEmpty || state.receivables.isEmpty) {
      state = state.copyWith(error: 'Please load both files before matching');
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await MatchingService.matchRecords(
        payments: state.payments,
        receivables: state.receivables,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      state = state.copyWith(
        result: result,
        originalCombinationMatches:
            result.combinationMatches, // Store original matches
        isLoading: false,
        progress: 0.0,
        currentStep: 1, // Move to results step
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error during matching: $e',
        progress: 0.0,
      );
    }
  }

  void selectCombinationOption(int paymentRow, int optionIndex) {
    if (state.result == null) return;

    // Get the selected option's receivable rows
    final selectedMatch = state.result!.combinationMatches
        .firstWhere((match) => match.payment.rowNumber == paymentRow);
    final selectedOption = selectedMatch.options[optionIndex];
    final selectedReceivableRows = selectedOption.receivables
        .map((receivable) => receivable.rowNumber)
        .toSet();

    // Check if this is a terminal-based combination
    if (selectedOption.isTerminalBased && selectedOption.terminalCode != null) {
      // Remove all rows from this terminal from other combinations
      final updatedResult = MatchingService.removeTerminalRows(
        state.result!,
        selectedOption.terminalCode!,
      );

      // Update the result
      state = state.copyWith(result: updatedResult);
      return;
    }

    // Update combination matches with conflict prevention
    final updatedCombinationMatches =
        state.result!.combinationMatches.map((match) {
      if (match.payment.rowNumber == paymentRow) {
        // This is the match being selected
        return CombinationMatch(
          payment: match.payment,
          options: match.options,
          selectedOptionIndex: optionIndex,
          isTerminalBased: match.isTerminalBased,
        );
      } else {
        // Check for conflicts with other matches
        final conflictingOptions = <int>[];

        for (int i = 0; i < match.options.length; i++) {
          final option = match.options[i];
          final optionReceivableRows = option.receivables
              .map((receivable) => receivable.rowNumber)
              .toSet();

          // Check if this option shares any receivable rows with the selected option
          final hasConflict = selectedReceivableRows
              .intersection(optionReceivableRows)
              .isNotEmpty;

          if (hasConflict) {
            conflictingOptions.add(i);
          }
        }

        // If there are conflicts, remove the conflicting options
        if (conflictingOptions.isNotEmpty) {
          final filteredOptions = <CombinationOption>[];
          for (int i = 0; i < match.options.length; i++) {
            if (!conflictingOptions.contains(i)) {
              filteredOptions.add(match.options[i]);
            }
          }

          // Adjust selected option index if needed
          int newSelectedIndex = match.selectedOptionIndex;
          if (newSelectedIndex >= 0) {
            // Count how many options were removed before this index
            int removedBefore = 0;
            for (int i = 0; i < newSelectedIndex; i++) {
              if (conflictingOptions.contains(i)) {
                removedBefore++;
              }
            }
            newSelectedIndex -= removedBefore;

            // If the selected option was removed, reset selection
            if (conflictingOptions.contains(match.selectedOptionIndex)) {
              newSelectedIndex = -1;
            }
          }

          return CombinationMatch(
            payment: match.payment,
            options: filteredOptions,
            selectedOptionIndex: newSelectedIndex,
            isTerminalBased: match.isTerminalBased,
          );
        }

        return match;
      }
    }).toList();

    final updatedResult = MatchingResult(
      exactMatches: state.result!.exactMatches,
      combinationMatches: updatedCombinationMatches,
      unmatchedPayments: state.result!.unmatchedPayments,
      unmatchedReceivables: state.result!.unmatchedReceivables,
      processingTime: state.result!.processingTime,
      userSelection: state.result!.userSelection,
    );

    state = state.copyWith(result: updatedResult);
  }

  void finalizeSelections() {
    if (state.result == null) return;

    // Create user selection map - only include combinations that have valid selections
    final selections = <int, int>{};
    final validCombinationMatches = <CombinationMatch>[];

    for (final match in state.result!.combinationMatches) {
      if (match.options.isNotEmpty && match.selectedOptionIndex >= 0) {
        // Only include combinations that have options and a valid selection
        selections[match.payment.rowNumber] = match.selectedOptionIndex;
        validCombinationMatches.add(match);
      }
      // Combinations with no options are excluded from final result
    }

    final userSelection = UserSelection(combinationSelections: selections);

    // Create updated result with only valid combinations
    final updatedResult = MatchingResult(
      exactMatches: state.result!.exactMatches,
      combinationMatches: validCombinationMatches,
      unmatchedPayments: state.result!.unmatchedPayments,
      unmatchedReceivables: state.result!.unmatchedReceivables,
      processingTime: state.result!.processingTime,
      userSelection: userSelection,
    );

    state = state.copyWith(
      result: updatedResult,
      currentStep: 3, // Move to export step
    );
  }

  void resetSelections() {
    if (state.result == null || state.originalCombinationMatches == null) {
      return;
    }

    // Restore original combination matches with no selections
    final restoredCombinationMatches =
        state.originalCombinationMatches!.map((match) {
      return CombinationMatch(
        payment: match.payment,
        options: match.options,
        selectedOptionIndex: -1,
      );
    }).toList();

    final updatedResult = MatchingResult(
      exactMatches: state.result!.exactMatches,
      combinationMatches: restoredCombinationMatches,
      unmatchedPayments: state.result!.unmatchedPayments,
      unmatchedReceivables: state.result!.unmatchedReceivables,
      processingTime: state.result!.processingTime,
      userSelection: null,
    );

    state = state.copyWith(result: updatedResult);
  }

  void setCurrentStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  Future<void> exportResults(String filePath) async {
    if (state.result == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      await ExcelService.writeResultsToExcel(
        filePath: filePath,
        results: state.result!.toMap(),
        sheetName: 'Matching Results',
      );

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error exporting results: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = MatchingState();
  }
}

final matchingProvider = StateNotifierProvider<MatchingNotifier, MatchingState>(
  (ref) => MatchingNotifier(),
);
