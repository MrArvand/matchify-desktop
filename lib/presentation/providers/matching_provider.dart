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
  final String? paymentsFilePath;
  final String? receivablesFilePath;
  final int paymentsAmountColumn;
  final int receivablesAmountColumn;
  final int currentStep; // 0: Upload, 1: Results, 2: Selection, 3: Export

  MatchingState({
    this.isLoading = false,
    this.progress = 0.0,
    this.error,
    this.payments = const [],
    this.receivables = const [],
    this.result,
    this.paymentsFilePath,
    this.receivablesFilePath,
    this.paymentsAmountColumn = 0,
    this.receivablesAmountColumn = 0,
    this.currentStep = 0,
  });

  MatchingState copyWith({
    bool? isLoading,
    double? progress,
    String? error,
    List<PaymentRecord>? payments,
    List<ReceivableRecord>? receivables,
    MatchingResult? result,
    String? paymentsFilePath,
    String? receivablesFilePath,
    int? paymentsAmountColumn,
    int? receivablesAmountColumn,
    int? currentStep,
  }) {
    return MatchingState(
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      payments: payments ?? this.payments,
      receivables: receivables ?? this.receivables,
      result: result ?? this.result,
      paymentsFilePath: paymentsFilePath ?? this.paymentsFilePath,
      receivablesFilePath: receivablesFilePath ?? this.receivablesFilePath,
      paymentsAmountColumn: paymentsAmountColumn ?? this.paymentsAmountColumn,
      receivablesAmountColumn:
          receivablesAmountColumn ?? this.receivablesAmountColumn,
      currentStep: currentStep ?? this.currentStep,
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

  void setPaymentsAmountColumn(int? columnIndex) {
    if (columnIndex != null) {
      state = state.copyWith(paymentsAmountColumn: columnIndex);
    }
  }

  void setReceivablesAmountColumn(int? columnIndex) {
    if (columnIndex != null) {
      state = state.copyWith(receivablesAmountColumn: columnIndex);
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

    final updatedCombinationMatches =
        state.result!.combinationMatches.map((match) {
      if (match.payment.rowNumber == paymentRow) {
        return CombinationMatch(
          payment: match.payment,
          options: match.options,
          selectedOptionIndex: optionIndex,
        );
      }
      return match;
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

    // Create user selection map
    final selections = <int, int>{};
    for (final match in state.result!.combinationMatches) {
      if (match.selectedOptionIndex >= 0) {
        selections[match.payment.rowNumber] = match.selectedOptionIndex;
      }
    }

    final userSelection = UserSelection(combinationSelections: selections);

    // Apply selections with conflict prevention
    final finalResult = MatchingService.applyUserSelections(
      state.result!,
      userSelection,
    );

    state = state.copyWith(
      result: finalResult,
      currentStep: 3, // Move to export step
    );
  }

  void resetSelections() {
    if (state.result == null) return;

    final updatedCombinationMatches =
        state.result!.combinationMatches.map((match) {
      return CombinationMatch(
        payment: match.payment,
        options: match.options,
        selectedOptionIndex: -1,
      );
    }).toList();

    final updatedResult = MatchingResult(
      exactMatches: state.result!.exactMatches,
      combinationMatches: updatedCombinationMatches,
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
