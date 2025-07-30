import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:matchify_desktop/core/models/matching_result.dart';
import 'package:matchify_desktop/core/utils/persian_number_formatter.dart';

class PrintService {
  static Future<void> printReport(MatchingResult result) async {
    try {
      final report = _generateReportText(result);

      // Create a temporary HTML file for printing
      final htmlContent = _generateHtmlReport(result);
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/matching_report.html');
      await tempFile.writeAsString(htmlContent);

      print('Debug: Temp file created at: ${tempFile.path}');
      print('Debug: File exists: ${await tempFile.exists()}');

      // Open the file with default browser for printing
      if (Platform.isWindows) {
        try {
          // Method 1: Try using the default browser directly
          print('Debug: Attempting to open with default browser...');
          final result =
              await Process.run('cmd', ['/c', 'start', '', tempFile.path]);
          print('Debug: start command exit code: ${result.exitCode}');
          print('Debug: start command stderr: ${result.stderr}');

          if (result.exitCode != 0) {
            // Method 2: Try using explorer
            print('Debug: Trying explorer fallback...');
            final explorerResult =
                await Process.run('explorer', [tempFile.path]);
            print('Debug: explorer exit code: ${explorerResult.exitCode}');
            print('Debug: explorer stderr: ${explorerResult.stderr}');

            if (explorerResult.exitCode != 0) {
              // Method 3: Try using rundll32
              print('Debug: Trying rundll32 fallback...');
              final rundllResult = await Process.run(
                  'rundll32', ['url.dll,FileProtocolHandler', tempFile.path]);
              print('Debug: rundll32 exit code: ${rundllResult.exitCode}');
              print('Debug: rundll32 stderr: ${rundllResult.stderr}');
            }
          }
        } catch (e) {
          print('Debug: Exception in Windows file opening: $e');
          // Final fallback: try using explorer
          await Process.run('explorer', [tempFile.path]);
        }
      } else if (Platform.isMacOS) {
        await Process.run('open', [tempFile.path]);
      } else {
        await Process.run('xdg-open', [tempFile.path]);
      }

      // Copy report to clipboard for manual printing
      await Clipboard.setData(ClipboardData(text: report));
    } catch (e) {
      print('Debug: Exception in printReport: $e');
      throw Exception('خطا در چاپ گزارش: $e');
    }
  }

  static String _generateReportText(MatchingResult result) {
    final buffer = StringBuffer();

    buffer.writeln('گزارش تطبیق مبالغ');
    buffer.writeln('=' * 50);
    buffer.writeln('تاریخ: ${DateTime.now().toLocal()}');
    buffer.writeln(
        'زمان پردازش: ${PersianNumberFormatter.formatNumber(result.processingTime.inMilliseconds)} میلی‌ثانیه');
    buffer.writeln();

    // Exact Matches
    buffer.writeln('تطبیق‌های دقیق:');
    buffer.writeln('-' * 30);
    for (final match in result.exactMatches) {
      buffer.writeln(
          'ردیف پرداخت ${PersianNumberFormatter.formatNumber(match.payment.rowNumber)} -> ردیف دریافت ${PersianNumberFormatter.formatNumber(match.receivable.rowNumber)}');
      buffer.writeln(
          'مبلغ: ${PersianNumberFormatter.formatCurrency(match.amount)}');
      buffer.writeln();
    }

    // Combination Matches
    if (result.combinationMatches.isNotEmpty) {
      buffer.writeln('تطبیق‌های ترکیبی:');
      buffer.writeln('-' * 30);
      for (final match in result.combinationMatches) {
        if (match.selectedOptionIndex >= 0) {
          final selectedOption = match.options[match.selectedOptionIndex];
          buffer.writeln(
              'ردیف پرداخت ${PersianNumberFormatter.formatNumber(match.payment.rowNumber)}:');
          buffer.writeln(
              'مبلغ پرداخت: ${PersianNumberFormatter.formatCurrency(match.payment.amount)}');
          buffer.writeln('ترکیب انتخاب شده:');
          for (final receivable in selectedOption.receivables) {
            buffer.writeln(
                '  - ردیف ${PersianNumberFormatter.formatNumber(receivable.rowNumber)}: ${PersianNumberFormatter.formatCurrency(receivable.amount)}');
          }
          buffer.writeln(
              'مجموع: ${PersianNumberFormatter.formatCurrency(selectedOption.totalAmount)}');
          buffer.writeln();
        }
      }
    }

    // Unmatched Payments
    if (result.unmatchedPayments.isNotEmpty) {
      buffer.writeln('پرداخت‌های نامطابق:');
      buffer.writeln('-' * 30);
      for (final payment in result.unmatchedPayments) {
        buffer.writeln(
            'ردیف ${PersianNumberFormatter.formatNumber(payment.rowNumber)}: ${PersianNumberFormatter.formatCurrency(payment.amount)}');
      }
      buffer.writeln();
    }

    // Unmatched Receivables
    if (result.unmatchedReceivables.isNotEmpty) {
      buffer.writeln('دریافت‌های نامطابق:');
      buffer.writeln('-' * 30);
      for (final receivable in result.unmatchedReceivables) {
        buffer.writeln(
            'ردیف ${PersianNumberFormatter.formatNumber(receivable.rowNumber)}: ${PersianNumberFormatter.formatCurrency(receivable.amount)}');
      }
      buffer.writeln();
    }

    // Summary
    buffer.writeln('خلاصه:');
    buffer.writeln('-' * 30);
    buffer.writeln(
        'تطبیق‌های دقیق: ${PersianNumberFormatter.formatNumber(result.totalExactMatches)}');
    buffer.writeln(
        'تطبیق‌های ترکیبی: ${PersianNumberFormatter.formatNumber(result.totalCombinationMatches)}');
    buffer.writeln(
        'پرداخت‌های نامطابق: ${PersianNumberFormatter.formatNumber(result.totalUnmatchedPayments)}');
    buffer.writeln(
        'دریافت‌های نامطابق: ${PersianNumberFormatter.formatNumber(result.totalUnmatchedReceivables)}');
    buffer.writeln(
        'مجموع مبالغ تطابق‌شده: ${PersianNumberFormatter.formatCurrency(result.totalMatchedAmount)}');

    return buffer.toString();
  }

  static String _generateHtmlReport(MatchingResult result) {
    return '''
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>گزارش تطبیق مبالغ</title>
    <style>
        body {
            font-family: 'Vazirmatn', 'Tahoma', 'Arial', sans-serif;
            margin: 20px;
            background-color: #f8f9fa;
            direction: rtl;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            text-align: center;
            border-bottom: 2px solid #6366f1;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        .section {
            margin-bottom: 30px;
        }
        .section-title {
            color: #6366f1;
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 15px;
            border-bottom: 1px solid #e5e7eb;
            padding-bottom: 8px;
        }
        .match-item {
            background-color: #f8f9fa;
            padding: 12px;
            margin-bottom: 8px;
            border-radius: 8px;
            border-right: 4px solid #6366f1;
        }
        .summary {
            background-color: #6366f1;
            color: white;
            padding: 20px;
            border-radius: 12px;
            margin-top: 30px;
        }
        .summary-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
        }
        @media print {
            body { background-color: white; }
            .container { box-shadow: none; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>گزارش تطبیق مبالغ</h1>
            <p>تاریخ: ${DateTime.now().toLocal()}</p>
            <p>زمان پردازش: ${PersianNumberFormatter.formatNumber(result.processingTime.inMilliseconds)} میلی‌ثانیه</p>
        </div>

        <div class="section">
            <div class="section-title">تطبیق‌های دقیق</div>
            ${result.exactMatches.map((match) => '''
                <div class="match-item">
                    <strong>ردیف پرداخت ${PersianNumberFormatter.formatNumber(match.payment.rowNumber)} → ردیف دریافت ${PersianNumberFormatter.formatNumber(match.receivable.rowNumber)}</strong><br>
                    مبلغ: ${PersianNumberFormatter.formatCurrency(match.amount)}
                </div>
            ''').join('')}
        </div>

        ${result.combinationMatches.isNotEmpty ? '''
        <div class="section">
            <div class="section-title">تطبیق‌های ترکیبی</div>
            ${result.combinationMatches.where((match) => match.selectedOptionIndex >= 0).map((match) {
            final selectedOption = match.options[match.selectedOptionIndex];
            return '''
                    <div class="match-item">
                        <strong>ردیف پرداخت ${PersianNumberFormatter.formatNumber(match.payment.rowNumber)}</strong><br>
                        مبلغ پرداخت: ${PersianNumberFormatter.formatCurrency(match.payment.amount)}<br>
                        ترکیب انتخاب شده:<br>
                        ${selectedOption.receivables.map((receivable) => '• ردیف ${PersianNumberFormatter.formatNumber(receivable.rowNumber)}: ${PersianNumberFormatter.formatCurrency(receivable.amount)}').join('<br>')}<br>
                        <strong>مجموع: ${PersianNumberFormatter.formatCurrency(selectedOption.totalAmount)}</strong>
                    </div>
                ''';
          }).join('')}
        </div>
        ''' : ''}

        ${result.unmatchedPayments.isNotEmpty ? '''
        <div class="section">
            <div class="section-title">پرداخت‌های نامطابق</div>
            ${result.unmatchedPayments.map((payment) => '''
                <div class="match-item">
                    ردیف ${PersianNumberFormatter.formatNumber(payment.rowNumber)}: ${PersianNumberFormatter.formatCurrency(payment.amount)}
                </div>
            ''').join('')}
        </div>
        ''' : ''}

        ${result.unmatchedReceivables.isNotEmpty ? '''
        <div class="section">
            <div class="section-title">دریافت‌های نامطابق</div>
            ${result.unmatchedReceivables.map((receivable) => '''
                <div class="match-item">
                    ردیف ${PersianNumberFormatter.formatNumber(receivable.rowNumber)}: ${PersianNumberFormatter.formatCurrency(receivable.amount)}
                </div>
            ''').join('')}
        </div>
        ''' : ''}

        <div class="summary">
            <h3>خلاصه</h3>
            <div class="summary-item">
                <span>تطبیق‌های دقیق:</span>
                <span>${PersianNumberFormatter.formatNumber(result.totalExactMatches)}</span>
            </div>
            <div class="summary-item">
                <span>تطبیق‌های ترکیبی:</span>
                <span>${PersianNumberFormatter.formatNumber(result.totalCombinationMatches)}</span>
            </div>
            <div class="summary-item">
                <span>پرداخت‌های نامطابق:</span>
                <span>${PersianNumberFormatter.formatNumber(result.totalUnmatchedPayments)}</span>
            </div>
            <div class="summary-item">
                <span>دریافت‌های نامطابق:</span>
                <span>${PersianNumberFormatter.formatNumber(result.totalUnmatchedReceivables)}</span>
            </div>
            <div class="summary-item">
                <span>مجموع مبالغ تطابق‌شده:</span>
                <span>${PersianNumberFormatter.formatCurrency(result.totalMatchedAmount)}</span>
            </div>
        </div>
    </div>
</body>
</html>
    ''';
  }
}
