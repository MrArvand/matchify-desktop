import 'package:matchify_desktop/core/models/record.dart';

class ExactMatch {
  final PaymentRecord payment;
  final ReceivableRecord receivable;

  ExactMatch({required this.payment, required this.receivable});

  int get amount => payment.amount;

  Map<String, dynamic> toMap() {
    return {
      'payment_row': payment.rowNumber,
      'receivable_row': receivable.rowNumber,
      'amount': amount,
    };
  }

  @override
  String toString() {
    return 'ExactMatch(payment: ${payment.rowNumber}, receivable: ${receivable.rowNumber}, amount: $amount)';
  }
}

class SystemTerminalSumMatch {
  final PaymentRecord payment;
  final List<ReceivableRecord> receivables;
  final String terminalCode;

  SystemTerminalSumMatch({
    required this.payment,
    required this.receivables,
    required this.terminalCode,
  });

  int get amount => payment.amount;

  int get totalReceivableAmount {
    return receivables.fold(0, (sum, receivable) => sum + receivable.amount);
  }

  List<int> get receivableRows => receivables.map((r) => r.rowNumber).toList();

  Map<String, dynamic> toMap() {
    return {
      'payment_row': payment.rowNumber,
      'receivable_rows': receivableRows,
      'amount': amount,
      'terminal_code': terminalCode,
    };
  }

  @override
  String toString() {
    return 'SystemTerminalSumMatch(payment: ${payment.rowNumber}, terminal: $terminalCode, receivables: ${receivableRows}, amount: $amount)';
  }
}

class CombinationOption {
  final List<ReceivableRecord> receivables;
  final int selectedIndex; // -1 means not selected
  final bool isTerminalBased; // Whether this is a terminal-based combination
  final String? terminalCode; // Terminal code if this is terminal-based

  CombinationOption({
    required this.receivables,
    this.selectedIndex = -1,
    this.isTerminalBased = false,
    this.terminalCode,
  });

  int get totalAmount {
    return receivables.fold(0, (sum, receivable) => sum + receivable.amount);
  }

  List<int> get receivableRows => receivables.map((r) => r.rowNumber).toList();
  List<int> get receivableAmounts =>
      receivables.map((r) => r.amount).toList();

  Map<String, dynamic> toMap() {
    return {
      'rows': receivableRows,
      'amounts': receivableAmounts,
      'isTerminalBased': isTerminalBased,
      'terminalCode': terminalCode,
    };
  }

  @override
  String toString() {
    return 'CombinationOption(receivables: ${receivableRows}, total: $totalAmount)';
  }
}

class CombinationMatch {
  final PaymentRecord payment;
  final List<CombinationOption> options;
  final int selectedOptionIndex; // -1 means not selected
  final bool isTerminalBased; // Whether this is a terminal-based combination

  CombinationMatch({
    required this.payment,
    required this.options,
    this.selectedOptionIndex = -1,
    this.isTerminalBased = false,
  });

  int get totalAmount {
    if (selectedOptionIndex >= 0 && selectedOptionIndex < options.length) {
      return options[selectedOptionIndex].totalAmount;
    }
    return 0;
  }

  List<ReceivableRecord> get selectedReceivables {
    if (selectedOptionIndex >= 0 && selectedOptionIndex < options.length) {
      return options[selectedOptionIndex].receivables;
    }
    return [];
  }

  Map<String, dynamic> toMap() {
    return {
      'payment_row': payment.rowNumber,
      'amount': payment.amount,
      'combinations': options.map((option) => option.toMap()).toList(),
      'selected_combination': selectedOptionIndex,
      'isTerminalBased': isTerminalBased,
    };
  }

  @override
  String toString() {
    return 'CombinationMatch(payment: ${payment.rowNumber}, options: ${options.length}, selected: $selectedOptionIndex)';
  }
}

class UserSelection {
  final Map<int, int> combinationSelections; // payment row -> selected option index

  UserSelection({required this.combinationSelections});

  Map<String, dynamic> toMap() {
    return {
      'combination_selections': combinationSelections,
    };
  }
}

class MatchingResult {
  final List<ExactMatch> exactMatches;
  final List<SystemTerminalSumMatch> systemTerminalSumMatches;
  final List<CombinationMatch> combinationMatches;
  final List<PaymentRecord> unmatchedPayments;
  final List<ReceivableRecord> unmatchedReceivables;
  final Duration processingTime;
  final UserSelection? userSelection;

  MatchingResult({
    required this.exactMatches,
    required this.systemTerminalSumMatches,
    required this.combinationMatches,
    required this.unmatchedPayments,
    required this.unmatchedReceivables,
    required this.processingTime,
    this.userSelection,
  });

  int get totalExactMatches => exactMatches.length;
  int get totalSystemTerminalSumMatches => systemTerminalSumMatches.length;
  int get totalCombinationMatches => combinationMatches.length;
  int get totalUnmatchedPayments => unmatchedPayments.length;
  int get totalUnmatchedReceivables => unmatchedReceivables.length;

  double get totalMatchedAmount {
    double exactAmount = exactMatches.fold(
      0.0,
      (sum, match) => sum + match.amount,
    );
    double systemTerminalAmount = systemTerminalSumMatches.fold(
      0.0,
      (sum, match) => sum + match.amount,
    );
    double combinationAmount = combinationMatches.fold(
      0.0,
      (sum, match) => sum + match.totalAmount,
    );
    return exactAmount + systemTerminalAmount + combinationAmount;
  }

  Map<String, dynamic> toMap() {
    return {
      'exact_matches': exactMatches.map((match) => match.toMap()).toList(),
      'system_terminal_sum_matches':
          systemTerminalSumMatches.map((match) => match.toMap()).toList(),
      'combination_matches': combinationMatches
          .map((match) => match.toMap())
          .toList(),
      'unmatched_payments': unmatchedPayments
          .map((payment) => payment.toMap())
          .toList(),
      'unmatched_receivables': unmatchedReceivables
          .map((receivable) => receivable.toMap())
          .toList(),
      'processing_time_ms': processingTime.inMilliseconds,
      'user_selection': userSelection?.toMap(),
      'statistics': {
        'total_exact_matches': totalExactMatches,
        'total_system_terminal_sum_matches': totalSystemTerminalSumMatches,
        'total_combination_matches': totalCombinationMatches,
        'total_unmatched_payments': totalUnmatchedPayments,
        'total_unmatched_receivables': totalUnmatchedReceivables,
        'total_matched_amount': totalMatchedAmount,
      },
    };
  }

  @override
  String toString() {
    return 'MatchingResult(system terminal: $totalSystemTerminalSumMatches, exact: $totalExactMatches, combinations: $totalCombinationMatches, unmatched payments: $totalUnmatchedPayments, unmatched receivables: $totalUnmatchedReceivables)';
  }
}
