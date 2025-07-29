class PersianNumberFormatter {
  static const Map<String, String> _englishToPersian = {
    '0': '۰',
    '1': '۱',
    '2': '۲',
    '3': '۳',
    '4': '۴',
    '5': '۵',
    '6': '۶',
    '7': '۷',
    '8': '۸',
    '9': '۹',
  };

  static const Map<String, String> _persianToEnglish = {
    '۰': '0',
    '۱': '1',
    '۲': '2',
    '۳': '3',
    '۴': '4',
    '۵': '5',
    '۶': '6',
    '۷': '7',
    '۸': '8',
    '۹': '9',
  };

  /// Convert English numbers to Persian numbers
  static String toPersian(String text) {
    String result = text;
    for (final entry in _englishToPersian.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  /// Convert Persian numbers to English numbers
  static String toEnglish(String text) {
    String result = text;
    for (final entry in _persianToEnglish.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  /// Format a number with Persian digits and comma separators
  static String formatNumber(dynamic number) {
    if (number == null) return '۰';
    
    String numStr = number.toString();
    
    // Handle decimal numbers
    if (numStr.contains('.')) {
      final parts = numStr.split('.');
      final integerPart = _addCommas(parts[0]);
      final decimalPart = parts[1];
      return '${toPersian(integerPart)}.${toPersian(decimalPart)}';
    }
    
    return toPersian(_addCommas(numStr));
  }

  /// Add Persian commas to a number string
  static String _addCommas(String number) {
    final result = StringBuffer();
    for (int i = 0; i < number.length; i++) {
      if (i > 0 && (number.length - i) % 3 == 0) {
        result.write('،');
      }
      result.write(number[i]);
    }
    return result.toString();
  }

  /// Format currency with Persian numbers
  static String formatCurrency(dynamic amount) {
    return '${formatNumber(amount)} ریال';
  }

  /// Format percentage with Persian numbers
  static String formatPercentage(dynamic percentage) {
    return '${formatNumber(percentage)}%';
  }
} 