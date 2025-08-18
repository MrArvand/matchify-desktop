import 'dart:async';
import 'package:matchify_desktop/core/constants/app_constants.dart';
import 'package:matchify_desktop/core/models/record.dart';
import 'package:matchify_desktop/core/models/matching_result.dart';
import 'package:matchify_desktop/core/utils/persian_number_formatter.dart';

class MatchingService {
  static const int _epsilon =
      100; // Precision for amount comparison (1 unit, since amounts are in cents)

  /// Main matching function that processes payments and receivables
  static Future<MatchingResult> matchRecords({
    required List<PaymentRecord> payments,
    required List<ReceivableRecord> receivables,
    required Function(double) onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Sort records by amount for efficient processing
    final sortedPayments = List<PaymentRecord>.from(payments)
      ..sort((a, b) => a.amount.compareTo(b.amount));
    final sortedReceivables = List<ReceivableRecord>.from(receivables)
      ..sort((a, b) => a.amount.compareTo(b.amount));

    // Create maps for efficient lookup
    final receivableMap = <int, List<ReceivableRecord>>{};
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
        (r) => (r.amount - payment.amount).abs() <= _epsilon,
      )) {
        unmatchedPayments.add(payment);
      }
    }

    // Update progress
    onProgress(0.3);

    // Process combination matches for unmatched payments
    final remainingReceivables =
        sortedReceivables.where((r) => !usedReceivables.contains(r)).toList();

    // Group remaining receivables by terminal code if present
    final Map<String, List<ReceivableRecord>> terminalGroups = {};
    for (final r in remainingReceivables) {
      final code = (r.additionalData['terminal_code'] ?? '').toString().trim();
      // Only group if terminal code is not empty
      if (code.isNotEmpty) {
        terminalGroups.putIfAbsent(code, () => []).add(r);
      }
    }

    // Debug: Check terminal code extraction
    print('DEBUG: Total remaining receivables: ${remainingReceivables.length}');
    print(
        'DEBUG: Receivables with terminal codes: ${remainingReceivables.where((r) => r.additionalData['terminal_code'] != null).length}');
    print(
        'DEBUG: Sample terminal codes: ${remainingReceivables.take(5).map((r) => r.additionalData['terminal_code']).toList()}');

    // Calculate terminal-based combinations first (highest priority)
    final terminalBasedCombinations = <CombinationMatch>[];
    final terminalUsedReceivables = <ReceivableRecord>{};

    // Debug: Print terminal groups
    print('DEBUG: Terminal groups found: ${terminalGroups.length}');
    for (final entry in terminalGroups.entries) {
      final terminalCode = entry.key;
      final terminalReceivables = entry.value;
      final terminalSum =
          terminalReceivables.fold<int>(0, (sum, r) => sum + r.amount);
      print(
          'DEBUG: Terminal $terminalCode: ${terminalReceivables.length} rows, sum: $terminalSum');
    }

    for (final payment in unmatchedPayments) {
      print(
          'DEBUG: Checking payment ${payment.rowNumber} with amount ${payment.amount}');

      // Try to find terminal groups that sum to the payment amount
      for (final entry in terminalGroups.entries) {
        final terminalCode = entry.key;
        final terminalReceivables = entry.value;

        // Skip if terminal has no receivables or if it's empty terminal code
        if (terminalReceivables.isEmpty || terminalCode.isEmpty) continue;

        // Calculate sum of all receivables in this terminal
        final terminalSum =
            terminalReceivables.fold<int>(0, (sum, r) => sum + r.amount);

        print(
            'DEBUG: Terminal $terminalCode sum: $terminalSum (${terminalSum / 100}), payment amount: ${payment.amount} (${payment.amount / 100}), diff: ${(terminalSum - payment.amount).abs()} (${(terminalSum - payment.amount).abs() / 100}), epsilon: $_epsilon (${_epsilon / 100})');

        // Check if terminal sum matches payment amount (within epsilon)
        if ((terminalSum - payment.amount).abs() <= _epsilon) {
          print(
              'DEBUG: MATCH FOUND! Terminal $terminalCode matches payment ${payment.rowNumber}');

          // Create terminal-based combination option
          final terminalOption = CombinationOption(
            receivables: terminalReceivables,
            isTerminalBased: true,
            terminalCode: terminalCode,
          );
          
          // Check if any receivables in this terminal are already used
          final hasConflict = terminalReceivables.any((r) =>
              usedReceivables.contains(r) ||
              terminalUsedReceivables.contains(r));

          if (!hasConflict) {
            print(
                'DEBUG: Adding terminal-based combination for payment ${payment.rowNumber}');
            // Add to terminal-based combinations
            terminalBasedCombinations.add(CombinationMatch(
              payment: payment,
              options: [terminalOption],
              isTerminalBased: true,
            ));

            // Mark all receivables in this terminal as used
            terminalUsedReceivables.addAll(terminalReceivables);
            usedReceivables.addAll(terminalReceivables);
          } else {
            print('DEBUG: Conflict detected for terminal $terminalCode');
          }
        }
      }
    }

    print(
        'DEBUG: Total terminal-based combinations found: ${terminalBasedCombinations.length}');

    // Remove terminal-based combinations from unmatched payments
    final terminalMatchedPayments =
        terminalBasedCombinations.map((m) => m.payment).toSet();
    final remainingUnmatchedPayments = unmatchedPayments
        .where((p) => !terminalMatchedPayments.contains(p))
        .toList();

    final int total = remainingUnmatchedPayments.length;
    int processed = 0;
    final DateTime hardDeadline = DateTime.now()
        .add(Duration(seconds: AppConstants.maxProcessingTimeSeconds));

    for (final payment in remainingUnmatchedPayments) {
      final options = <CombinationOption>[];

      // Per-payment soft budget slice
      final int perPaymentMillis = (AppConstants.maxProcessingTimeSeconds *
              1000 ~/
              (total == 0 ? 1 : total))
          .clamp(100, 800);
      final DateTime perPaymentDeadline =
          DateTime.now().add(Duration(milliseconds: perPaymentMillis));

      // Try terminal-constrained search first
      for (final group in terminalGroups.values) {
        if (DateTime.now().isAfter(perPaymentDeadline) ||
            DateTime.now().isAfter(hardDeadline)) {
          break;
        }
        final combos = _subsetSumTopK(
          targetAmount: payment.amount,
          candidates: group,
          maxOptions: 10,
        );
        for (final c in combos) {
          options.add(CombinationOption(receivables: c));
          if (options.length >= 10) break;
        }
        if (options.isNotEmpty) break; // prefer within a single group
      }

      // Fallback: small cross-group if nothing found and time permits
      if (options.isEmpty &&
          !DateTime.now().isAfter(perPaymentDeadline) &&
          !DateTime.now().isAfter(hardDeadline)) {
        final combos = await _findCombinations(
          payment.amount,
          remainingReceivables,
          usedReceivables,
        );
        for (final c in combos.take(5)) {
          options.add(CombinationOption(receivables: c));
        }
      }

      if (options.isNotEmpty) {
        combinationMatches.add(
          CombinationMatch(payment: payment, options: options),
        );
      }

      processed++;
      if (total > 0) {
        onProgress(0.3 + 0.5 * (processed / total));
      }

      if (DateTime.now().isAfter(hardDeadline)) {
        break;
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
    
    // Combine terminal-based and regular combination matches
    final allCombinationMatches = [
      ...terminalBasedCombinations,
      ...combinationMatches
    ];
    
    return MatchingResult(
      exactMatches: exactMatches,
      combinationMatches: allCombinationMatches,
      unmatchedPayments: remainingUnmatchedPayments,
      unmatchedReceivables: unmatchedReceivables,
      processingTime: stopwatch.elapsed,
    );
  }

  /// Terminal-constrained subset sum using meet-in-the-middle with pruning.
  static List<List<ReceivableRecord>> _subsetSumTopK({
    required int targetAmount,
    required List<ReceivableRecord> candidates,
    required int maxOptions,
  }) {
    if (candidates.isEmpty || maxOptions <= 0) return [];

    // Use integer amounts directly
    final intTarget = targetAmount;
    final values = candidates.map((r) => r.amount).toList(growable: false);

    // Quick bound: remove items > target
    final idxs = <int>[];
    for (int i = 0; i < candidates.length; i++) {
      if (values[i] <= intTarget) idxs.add(i);
    }
    if (idxs.isEmpty) return [];

    final leftSize = idxs.length ~/ 2;
    final leftIdxs = idxs.sublist(0, leftSize);
    final rightIdxs = idxs.sublist(leftSize);

    List<(int sum, List<int> picks)> enumerate(List<int> subset) {
      final results = <(int, List<int>)>[];
      final int n = subset.length;
      final int totalMasks = 1 << n;
      // Cap enumeration to avoid blow-up
      final int hardCap = 1 << 18; // ~262k
      final int limit = totalMasks > hardCap ? hardCap : totalMasks;
      for (int mask = 1; mask < limit; mask++) {
        int sum = 0;
        final chosen = <int>[];
        for (int b = 0; b < n; b++) {
          if ((mask & (1 << b)) != 0) {
            final gi = subset[b];
            sum += values[gi];
            if (sum > intTarget) break;
            chosen.add(gi);
          }
        }
        if (sum <= intTarget) {
          results.add((sum, chosen));
        }
        if (results.length > 200000) break; // extra safeguard
      }
      results.sort((a, b) => a.$1.compareTo(b.$1));
      return results;
    }

    final left = enumerate(leftIdxs);
    final right = enumerate(rightIdxs);

    // Two-pointer to find exact target
    int i = 0;
    int j = right.length - 1;
    final found = <List<ReceivableRecord>>[];
    final seenCombinations = <String>{};

    while (i < left.length && j >= 0 && found.length < maxOptions) {
      final s = left[i].$1 + right[j].$1;
      if (s == intTarget) {
        final comboIdxs = [...left[i].$2, ...right[j].$2];
        final combo = comboIdxs.map((gi) => candidates[gi]).toList();

        // Create a unique key for this combination (sorted row numbers)
        final sortedRows = combo.map((r) => r.rowNumber).toList()..sort();
        final combinationKey = sortedRows.join(',');

        // Only add if we haven't seen this combination before
        if (!seenCombinations.contains(combinationKey)) {
          seenCombinations.add(combinationKey);
          found.add(combo);
        }

        i++;
        j--;
      } else if (s < intTarget) {
        i++;
      } else {
        j--;
      }
    }

    return found;
  }

  /// Find combinations of receivables that sum to the target amount
  static Future<List<List<ReceivableRecord>>> _findCombinations(
    int targetAmount,
    List<ReceivableRecord> receivables,
    Set<ReceivableRecord> usedReceivables,
  ) async {
    // Filter out receivables larger than target amount
    final candidates = receivables
        .where((r) => r.amount <= targetAmount && !usedReceivables.contains(r))
        .toList();

    if (candidates.isEmpty) return [];

    final allCombinations = <List<ReceivableRecord>>[];
    final seenCombinations = <String>{};

    // Try 2-combinations first (more efficient)
    final combinations2 = _findCombinationsOfSize(targetAmount, candidates, 2);
    allCombinations
        .addAll(_deduplicateCombinations(combinations2, seenCombinations));

    // Try 3-combinations if no 2-combination found
    if (allCombinations.isEmpty) {
      final combinations3 =
          _findCombinationsOfSize(targetAmount, candidates, 3);
      allCombinations
          .addAll(_deduplicateCombinations(combinations3, seenCombinations));
    }

    // Try 4 and 5 combinations if still no matches found
    if (allCombinations.isEmpty) {
      final combinations4 =
          _findCombinationsOfSize(targetAmount, candidates, 4);
      allCombinations
          .addAll(_deduplicateCombinations(combinations4, seenCombinations));
    }

    if (allCombinations.isEmpty) {
      final combinations5 =
          _findCombinationsOfSize(targetAmount, candidates, 5);
      allCombinations
          .addAll(_deduplicateCombinations(combinations5, seenCombinations));
    }

    return allCombinations;
  }

  /// Find combinations of specific size using meet-in-the-middle technique
  static List<List<ReceivableRecord>> _findCombinationsOfSize(
    int targetAmount,
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

  /// Deduplicate combinations by treating them as unordered sets
  static List<List<ReceivableRecord>> _deduplicateCombinations(
    List<List<ReceivableRecord>> combinations,
    Set<String> seenCombinations,
  ) {
    final uniqueCombinations = <List<ReceivableRecord>>[];

    for (final combination in combinations) {
      // Create a unique key for this combination (sorted row numbers)
      final sortedRows = combination.map((r) => r.rowNumber).toList()..sort();
      final combinationKey = sortedRows.join(',');

      // Only add if we haven't seen this combination before
      if (!seenCombinations.contains(combinationKey)) {
        seenCombinations.add(combinationKey);
        uniqueCombinations.add(combination);
      }
    }

    return uniqueCombinations;
  }

  /// Find 2-combinations using two-pointer technique
  static List<List<ReceivableRecord>> _find2Combinations(
    int targetAmount,
    List<ReceivableRecord> candidates,
  ) {
    final results = <List<ReceivableRecord>>[];
    final seenPairs = <String>{};
    final sorted = List<ReceivableRecord>.from(candidates)
      ..sort((a, b) => a.amount.compareTo(b.amount));

    int left = 0;
    int right = sorted.length - 1;

    while (left < right) {
      final sum = sorted[left].amount + sorted[right].amount;
      final diff = (sum - targetAmount).abs();

      if (diff < _epsilon) {
        // Create a unique key for this pair (sorted row numbers)
        final row1 = sorted[left].rowNumber;
        final row2 = sorted[right].rowNumber;
        final pairKey = row1 < row2 ? '$row1,$row2' : '$row2,$row1';

        // Only add if we haven't seen this pair before
        if (!seenPairs.contains(pairKey)) {
          seenPairs.add(pairKey);
          results.add([sorted[left], sorted[right]]);
        }
        
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
    int targetAmount,
    List<ReceivableRecord> candidates,
  ) {
    final results = <List<ReceivableRecord>>[];
    final seenTriplets = <String>{};
    final sorted = List<ReceivableRecord>.from(candidates)
      ..sort((a, b) => a.amount.compareTo(b.amount));

    // Create map of 2-combination sums
    final twoCombinations = <int, List<List<ReceivableRecord>>>{};

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
            
            // Create a unique key for this triplet (sorted row numbers)
            final sortedRows = result.map((r) => r.rowNumber).toList()..sort();
            final tripletKey = sortedRows.join(',');

            // Only add if we haven't seen this triplet before
            if (!seenTriplets.contains(tripletKey)) {
              seenTriplets.add(tripletKey);
              results.add(result);
            }
          }
        }
      }
    }

    return results;
  }

  /// Find 4-combinations using meet-in-the-middle
  static List<List<ReceivableRecord>> _find4Combinations(
    int targetAmount,
    List<ReceivableRecord> candidates,
  ) {
    final results = <List<ReceivableRecord>>[];
    final sorted = List<ReceivableRecord>.from(candidates)
      ..sort((a, b) => a.amount.compareTo(b.amount));

    // Create map of 2-combination sums
    final twoCombinations = <int, List<List<ReceivableRecord>>>{};

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
    int targetAmount,
    List<ReceivableRecord> candidates,
  ) {
    final results = <List<ReceivableRecord>>[];
    final sorted = List<ReceivableRecord>.from(candidates)
      ..sort((a, b) => a.amount.compareTo(b.amount));

    // Create map of 2-combination and 3-combination sums
    final twoCombinations = <int, List<List<ReceivableRecord>>>{};
    final threeCombinations = <int, List<List<ReceivableRecord>>>{};

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

  /// Parse amount string to int, handling Persian comma formatting
  static int parseAmount(String amountStr) {
    if (amountStr.isEmpty) return 0;

    // Remove Persian/Arabic commas and spaces
    String cleaned = amountStr.replaceAll(RegExp(r'[،\s]'), '');

    // Handle different decimal separators and convert to integer
    cleaned = cleaned.replaceAll(',', '.');

    try {
      final doubleValue = double.parse(cleaned);
      return doubleValue.round(); // Parse as whole number, not cents
    } catch (e) {
      return 0;
    }
  }

  /// Format amount with Persian comma formatting (no decimals)
  static String formatAmount(int amount) {
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
            isTerminalBased: match.isTerminalBased,
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

  /// Remove terminal rows from all combinations when a terminal combination is selected
  static MatchingResult removeTerminalRows(
    MatchingResult result,
    String terminalCode,
  ) {
    final updatedCombinationMatches = <CombinationMatch>[];
    
    for (final match in result.combinationMatches) {
      // Skip if this is the selected terminal match
      if (match.isTerminalBased &&
          match.options.isNotEmpty &&
          match.options.first.terminalCode == terminalCode) {
        continue; // Remove this match entirely
      }
      
      // Filter out options that contain rows from the selected terminal
      final filteredOptions = <CombinationOption>[];
      for (final option in match.options) {
        final hasTerminalRows = option.receivables.any((r) =>
            r.additionalData['terminal_code']?.toString() == terminalCode);
        
        if (!hasTerminalRows) {
          filteredOptions.add(option);
        }
      }
      
      // Only keep matches that still have options
      if (filteredOptions.isNotEmpty) {
        updatedCombinationMatches.add(CombinationMatch(
          payment: match.payment,
          options: filteredOptions,
          selectedOptionIndex: match.selectedOptionIndex,
          isTerminalBased: match.isTerminalBased,
        ));
      }
    }
    
    return MatchingResult(
      exactMatches: result.exactMatches,
      combinationMatches: updatedCombinationMatches,
      unmatchedPayments: result.unmatchedPayments,
      unmatchedReceivables: result.unmatchedReceivables,
      processingTime: result.processingTime,
      userSelection: result.userSelection,
    );
  }

  // Ref code based combinations removed
}
