class AppConstants {
  // Storage box names
  static const String settingsBox = 'settings';
  static const String matchesBox = 'matches';

  // File types
  static const List<String> supportedExcelExtensions = ['.xlsx', '.xls'];

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;

  // File naming constants
  static const String varangarFileTitle = 'خروجی فاکتورهای ورانگر';
  static const String varangarFileSubtitle = 'مبالغ فاکتورهای ورانگر';
  static const String varangarShortName = 'ورانگر';

  static const String bankFileTitle = 'خروجی تراکنش های بانک';
  static const String bankFileSubtitle = 'مبالغ تراکنش های بانک';
  static const String bankShortName = 'بانک';

  // Algorithm Constants
  static const int maxCombinationSize = 3;
  static const double amountPrecision = 0.01;

  // Performance Constants
  static const int maxRecordsPerFile = 10000;
  static const int maxProcessingTimeSeconds = 60;
}
