import 'dart:async';
import 'dart:math';
import 'package:matchify_desktop/core/models/record.dart';
import 'package:matchify_desktop/core/models/matching_result.dart';
import 'package:matchify_desktop/core/constants/app_constants.dart';
import 'package:matchify_desktop/core/utils/persian_number_formatter.dart';

class MatchingService {
  static const double _epsilon = 0.01; // Precision for amount comparison

  /// Main matching function that processes payments and receivables
  static Future<MatchingResult> matchRecords({
    required List<PaymentRecord> payments,
    required List<ReceivableRecord> receivables,
    required Function(double) onProgress,
    bool useRefCodeMatching = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Sort records by amount for efficient processing
    final sortedPayments = List<PaymentRecord>.from(payments)
      ..sort((a, b) => a.amount.compareTo(b.amount));
    final sortedReceivables = List<ReceivableRecord>.from(receivables)
      ..sort((a, b) => a.amount.compareTo(b.amount));

    // Create maps for efficient lookup
    final receivableMap = <double, List<ReceivableRecord>>{};
    for (final receivable in sortedReceivables) {
      receivableMap.putIfAbsent(receivable.amount, () => []).add(receivable);
    }

    final List<ExactMatch> exactMatches = [];
    final List<CombinationMatch> combinationMatches = [];
    final List<PaymentRecord> unmatchedPayments = [];
    final Set<ReceivableRecord> usedReceivables = {};

    // Process exact matches first
    for (final payment in sortedPayments) {
      final matchingReceivables = receivableMap[payment.amount];
      if (matchingReceivables != null && matchingReceivables.isNotEmpty) {
        // Find first unused receivable with exact amount
        for (final receivable in matchingReceivables) {
          if (!usedReceivables.contains(receivable)) {
            exactMatches.add(
              ExactMatch(payment: payment, receivable: receivable),
            );
            usedReceivables.add(receivable);
            break;
          }
        }
      }

      if (!usedReceivables.any(
        (r) => (r.amount - payment.amount).abs() < _epsilon,
      )) {
        unmatchedPayments.add(payment);
      }
    }

    // Update progress
    onProgress(0.3);

    // Process combination matches for unmatched payments
    final remainingReceivables =
        sortedReceivables.where((r) => !usedReceivables.contains(r)).toList();

    if (useRefCodeMatching) {
      // Use ref code based matching
      final refCodeMatches = await _findRefCodeCombinations(
        unmatchedPayments,
        remainingReceivables,
        usedReceivables,
        onProgress,
      );
      combinationMatches.addAll(refCodeMatches);
    } else {
      // Use traditional meet-in-the-middle algorithm
      for (final payment in unmatchedPayments) {
        final combinations = await _findCombinations(
          payment.amount,
          remainingReceivables,
          usedReceivables,
        );

        if (combinations.isNotEmpty) {
          final options = combinations
              .map((combination) => CombinationOption(receivables: combination))
              .toList();

          combinationMatches.add(
            CombinationMatch(payment: payment, options: options),
          );
          // Don't mark receivables as used yet - let user choose
        }
      }
    }

    // Update progress
    onProgress(0.8);

    // Find unmatched receivables
    final unmatchedReceivables =
        sortedReceivables.where((r) => !usedReceivables.contains(r)).toList();

    // Update progress
    onProgress(1.0);

    stopwatch.stop();
    return MatchingResult(
      exactMatches: exactMatches,
      combinationMatches: combinationMatches,
      unmatchedPayments: unmatchedPayments,
      unmatchedReceivables: unmatchedReceivables,
      processingTime: stopwatch.elapsed,
    );
  }

  /// Find combinations of receivables that sum to the target amount
  static Future<List<List<ReceivableRecord>>> _findCombinations(
    double targetAmount,
    List<ReceivableRecord> receivables,
    Set<ReceivableRecord> usedReceivables,
  ) async {
    // Filter out receivables larger than target amount
    final candidates = receivables
        .where((r) => r.amount <= targetAmount && !usedReceivables.contains(r))
        .toList();

    if (candidates.isEmpty) return [];

    final allCombinations = <List<ReceivableRecord>>[];

    // Try 2-combinations first (more efficient)
    final combinations2 = _findCombinationsOfSize(targetAmount, candidates, 2);
    allCombinations.addAll(combinations2);

    // Try 3-combinations if no 2-combination found
    if (allCombinations.isEmpty) {
      final combinations3 =
          _findCombinationsOfSize(targetAmount, candidates, 3);
      allCombinations.addAll(combinations3);
    }

    // Try 4 and 5 combinations if still no matches found
    if (allCombinations.isEmpty) {
      final combinations4 =
          _findCombinationsOfSize(targetAmount, candidates, 4);
      allCombinations.addAll(combinations4);
    }

    if (allCombinations.isEmpty) {
      final combinations5 =
          _findCombinationsOfSize(targetAmount, candidates, 5);
      allCombinations.addAll(combinations5);
    }

    return allCombinations;
  }

  /// Find combinations of specific size using meet-in-the-middle technique
  static List<List<ReceivableRecord>> _findCombinationsOfSize(
    double targetAmount,
    List<ReceivableRecord> candidates,
    int size,
  ) {
    if (size == 2) {
      return _find2Combinations(targetAmount, candidates);
    } else if (size == 3) {
      return _find3Combinations(targetAmount, candidates);
    } else if (size == 4) {
      return _find4Combinations(targetAmount, candidates);
    } else if (size == 5) {
      return _find5Combinations(targetAmount, candidates);
    }
    return [];
  }

  /// Find 2-combinations using two-pointer technique
  static List<List<ReceivableRecord>> _find2Combinations(
    double targetAmount,
    List<ReceivableRecord> candidates,
  ) {
    final results = <List<ReceivableRecord>>[];
    final sorted = List<ReceivableRecord>.from(candidates)
      ..sort((a, b) => a.amount.compareTo(b.amount));

    int left = 0;
    int right = sorted.length - 1;

    while (left < right) {
      final sum = sorted[left].amount + sorted[right].amount;
      final diff = (sum - targetAmount).abs();

      if (diff < _epsilon) {
        results.add([sorted[left], sorted[right]]);
        left++;
        right--;
      } else if (sum < targetAmount) {
        left++;
      } else {
        right--;
      }
    }

    return results;
  }

  /// Find 3-combinations using meet-in-the-middle
  static List<List<ReceivableRecord>> _find3Combinations(
    double targetAmount,
    List<ReceivableRecord> candidates,
  ) {
    final results = <List<ReceivableRecord>>[];
    final sorted = List<ReceivableRecord>.from(candidates)
      ..sort((a, b) => a.amount.compareTo(b.amount));

    // Create map of 2-combination sums
    final twoCombinations = <double, List<List<ReceivableRecord>>>{};

    for (int i = 0; i < sorted.length - 1; i++) {
      for (int j = i + 1; j < sorted.length; j++) {
        final sum = sorted[i].amount + sorted[j].amount;
        if (sum <= targetAmount) {
          twoCombinations.putIfAbsent(sum, () => []).add([
            sorted[i],
            sorted[j],
          ]);
        }
      }
    }

    // Find third element that completes the combination
    for (final candidate in sorted) {
      final remaining = targetAmount - candidate.amount;
      final combinations = twoCombinations[remaining];

      if (combinations != null) {
        for (final combination in combinations) {
          // Check if candidate is not already in the combination
          if (!combination.contains(candidate)) {
            final result = [candidate, ...combination];
            results.add(result);
          }
        }
      }
    }

    return results;
  }

  /// Find 4-combinations using meet-in-the-middle
  static List<List<ReceivableRecord>> _find4Combinations(
    double targetAmount,
    List<ReceivableRecord> candidates,
  ) {
    final results = <List<ReceivableRecord>>[];
    final sorted = List<ReceivableRecord>.from(candidates)
      ..sort((a, b) => a.amount.compareTo(b.amount));

    // Create map of 2-combination sums
    final twoCombinations = <double, List<List<ReceivableRecord>>>{};

    for (int i = 0; i < sorted.length - 1; i++) {
      for (int j = i + 1; j < sorted.length; j++) {
        final sum = sorted[i].amount + sorted[j].amount;
        if (sum <= targetAmount) {
          twoCombinations.putIfAbsent(sum, () => []).add([
            sorted[i],
            sorted[j],
          ]);
        }
      }
    }

    // Find pairs of 2-combinations that sum to target
    for (final entry1 in twoCombinations.entries) {
      for (final entry2 in twoCombinations.entries) {
        if (entry1.key + entry2.key == targetAmount) {
          for (final combination1 in entry1.value) {
            for (final combination2 in entry2.value) {
              // Check for no overlapping elements
              final allElements = [...combination1, ...combination2];
              if (allElements.length == 4) {
                results.add(allElements);
              }
            }
          }
        }
      }
    }

    return results;
  }

  /// Find 5-combinations using meet-in-the-middle
  static List<List<ReceivableRecord>> _find5Combinations(
    double targetAmount,
    List<ReceivableRecord> candidates,
  ) {
    final results = <List<ReceivableRecord>>[];
    final sorted = List<ReceivableRecord>.from(candidates)
      ..sort((a, b) => a.amount.compareTo(b.amount));

    // Create map of 2-combination and 3-combination sums
    final twoCombinations = <double, List<List<ReceivableRecord>>>{};
    final threeCombinations = <double, List<List<ReceivableRecord>>>{};

    // Generate 2-combinations
    for (int i = 0; i < sorted.length - 1; i++) {
      for (int j = i + 1; j < sorted.length; j++) {
        final sum = sorted[i].amount + sorted[j].amount;
        if (sum <= targetAmount) {
          twoCombinations.putIfAbsent(sum, () => []).add([
            sorted[i],
            sorted[j],
          ]);
        }
      }
    }

    // Generate 3-combinations
    for (int i = 0; i < sorted.length - 2; i++) {
      for (int j = i + 1; j < sorted.length - 1; j++) {
        for (int k = j + 1; k < sorted.length; k++) {
          final sum = sorted[i].amount + sorted[j].amount + sorted[k].amount;
          if (sum <= targetAmount) {
            threeCombinations.putIfAbsent(sum, () => []).add([
              sorted[i],
              sorted[j],
              sorted[k],
            ]);
          }
        }
      }
    }

    // Find combinations that sum to target (2+3 or 3+2)
    for (final entry2 in twoCombinations.entries) {
      for (final entry3 in threeCombinations.entries) {
        if (entry2.key + entry3.key == targetAmount) {
          for (final combination2 in entry2.value) {
            for (final combination3 in entry3.value) {
              // Check for no overlapping elements
              final allElements = [...combination2, ...combination3];
              if (allElements.length == 5) {
                results.add(allElements);
              }
            }
          }
        }
      }
    }

    return results;
  }

  /// Parse amount string to double, handling Persian comma formatting
  static double parseAmount(String amountStr) {
    if (amountStr.isEmpty) return 0.0;

    // Remove Persian/Arabic commas and spaces
    String cleaned = amountStr.replaceAll(RegExp(r'[،\s]'), '');

    // Handle different decimal separators
    cleaned = cleaned.replaceAll(',', '.');

    try {
      return double.parse(cleaned);
    } catch (e) {
      return 0.0;
    }
  }

  /// Format amount with Persian comma formatting
  static String formatAmount(double amount) {
    return PersianNumberFormatter.formatNumber(amount);
  }

  /// Apply user selections and remove conflicts
  static MatchingResult applyUserSelections(
    MatchingResult originalResult,
    UserSelection userSelection,
  ) {
    final Set<ReceivableRecord> usedReceivables = {};

    // Add exact matches to used receivables
    for (final match in originalResult.exactMatches) {
      usedReceivables.add(match.receivable);
    }

    // Apply user selections and remove conflicts
    final updatedCombinationMatches = <CombinationMatch>[];

    for (final match in originalResult.combinationMatches) {
      final selectedOptionIndex =
          userSelection.combinationSelections[match.payment.rowNumber];

      if (selectedOptionIndex != null &&
          selectedOptionIndex >= 0 &&
          selectedOptionIndex < match.options.length) {
        final selectedOption = match.options[selectedOptionIndex];

        // Check if any receivables in this selection are already used
        final hasConflict =
            selectedOption.receivables.any((r) => usedReceivables.contains(r));

        if (!hasConflict) {
          // Add selected receivables to used set
          usedReceivables.addAll(selectedOption.receivables);

          // Create updated match with only the selected option
          updatedCombinationMatches.add(CombinationMatch(
            payment: match.payment,
            options: [selectedOption],
            selectedOptionIndex: 0,
          ));
        }
      }
    }

    // Find unmatched receivables after applying selections
    final allReceivables =
        originalResult.exactMatches.map((m) => m.receivable).toList();
    for (final match in updatedCombinationMatches) {
      if (match.selectedOptionIndex >= 0) {
        allReceivables
            .addAll(match.options[match.selectedOptionIndex].receivables);
      }
    }

    final originalAllReceivables =
        originalResult.exactMatches.map((m) => m.receivable).toList();
    for (final match in originalResult.combinationMatches) {
      for (final option in match.options) {
        originalAllReceivables.addAll(option.receivables);
      }
    }

    final unmatchedReceivables = originalAllReceivables
        .where((r) => !allReceivables.contains(r))
        .toList();

    return MatchingResult(
      exactMatches: originalResult.exactMatches,
      combinationMatches: updatedCombinationMatches,
      unmatchedPayments: originalResult.unmatchedPayments,
      unmatchedReceivables: unmatchedReceivables,
      processingTime: originalResult.processingTime,
      userSelection: userSelection,
    );
  }

  /// Find combinations using ref code grouping
  static Future<List<CombinationMatch>> _findRefCodeCombinations(
    List<PaymentRecord> unmatchedPayments,
    List<ReceivableRecord> remainingReceivables,
    Set<ReceivableRecord> usedReceivables,
    Function(double) onProgress,
  ) async {
    final combinationMatches = <CombinationMatch>[];

    // Group receivables by ref code
    final refCodeGroups = <String, List<ReceivableRecord>>{};
    for (final receivable in remainingReceivables) {
      if (receivable.refCode != null && receivable.refCode!.isNotEmpty) {
        refCodeGroups
            .putIfAbsent(receivable.refCode!, () => [])
            .add(receivable);
      }
    }

    // Calculate sum for each ref code group
    final refCodeSums = <String, double>{};
    for (final entry in refCodeGroups.entries) {
      refCodeSums[entry.key] =
          entry.value.fold(0.0, (sum, r) => sum + r.amount);
    }

    // Process each unmatched payment
    for (int i = 0; i < unmatchedPayments.length; i++) {
      final payment = unmatchedPayments[i];

      // Find ref codes that sum to the payment amount
      final matchingRefCodes = <String>[];
      for (final entry in refCodeSums.entries) {
        if ((entry.value - payment.amount).abs() < _epsilon) {
          matchingRefCodes.add(entry.key);
        }
      }

      if (matchingRefCodes.isNotEmpty) {
        // Create combination options for each matching ref code
        final options = matchingRefCodes.map((refCode) {
          return CombinationOption(receivables: refCodeGroups[refCode]!);
        }).toList();

        combinationMatches.add(
          CombinationMatch(payment: payment, options: options),
        );
      }

      // Update progress
      onProgress(0.3 + (0.5 * i / unmatchedPayments.length));
    }

    return combinationMatches;
  }
}
