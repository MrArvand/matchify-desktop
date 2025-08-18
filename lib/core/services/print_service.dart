import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:matchify_desktop/core/models/matching_result.dart';
import 'package:matchify_desktop/core/utils/persian_number_formatter.dart';
import 'package:matchify_desktop/core/constants/app_constants.dart';

class PrintService {
  static Future<void> printReport(MatchingResult result) async {
    try {
      final report = _generateReportText(result);

      // Create a temporary HTML file for printing
      final htmlContent = _generateHtmlReport(result);
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/matching_report.html');
      
      // Copy Vazirmatn font files to temp directory
      await _copyFontFiles(tempDir.path);
      
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

  /// Copy Vazirmatn font files to the specified directory
  static Future<void> _copyFontFiles(String targetDir) async {
    try {
      // List of font files to copy
      final fontFiles = [
        'Vazirmatn-Regular.ttf',
        'Vazirmatn-Bold.ttf',
        'Vazirmatn-Medium.ttf',
      ];

      for (final fontFile in fontFiles) {
        final sourcePath = 'assets/fonts/$fontFile';
        final targetPath = '$targetDir/$fontFile';

        // Check if source file exists
        final sourceFile = File(sourcePath);
        if (await sourceFile.exists()) {
          await sourceFile.copy(targetPath);
          print('Debug: Copied font file: $fontFile');
        } else {
          print('Debug: Font file not found: $sourcePath');
        }
      }
    } catch (e) {
      print('Debug: Error copying font files: $e');
      // Continue without fonts if there's an error
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
          'ردیف ${AppConstants.varangarShortName} ${PersianNumberFormatter.formatNumber(match.payment.rowNumber)} -> ردیف ${AppConstants.bankShortName} ${PersianNumberFormatter.formatNumber(match.receivable.rowNumber)}');
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
              'ردیف ${AppConstants.varangarShortName} ${PersianNumberFormatter.formatNumber(match.payment.rowNumber)}:');
          buffer.writeln(
              'مبلغ ${AppConstants.varangarShortName}: ${PersianNumberFormatter.formatCurrency(match.payment.amount)}');
          buffer.writeln('ترکیب انتخاب شده:');
          for (final receivable in selectedOption.receivables) {
            buffer.writeln(
                '  - ردیف ${AppConstants.bankShortName} ${PersianNumberFormatter.formatNumber(receivable.rowNumber)}: ${PersianNumberFormatter.formatCurrency(receivable.amount)}');
          }
          buffer.writeln(
              'مجموع: ${PersianNumberFormatter.formatCurrency(selectedOption.totalAmount)}');
          buffer.writeln();
        }
      }
    }

    // Unmatched Payments
    if (result.unmatchedPayments.isNotEmpty) {
      buffer.writeln('${AppConstants.varangarShortName} نامطابق:');
      buffer.writeln('-' * 30);
      for (final payment in result.unmatchedPayments) {
        buffer.writeln(
            'ردیف ${PersianNumberFormatter.formatNumber(payment.rowNumber)}: ${PersianNumberFormatter.formatCurrency(payment.amount)}');
      }
      buffer.writeln();
    }

    // Unmatched Receivables
    if (result.unmatchedReceivables.isNotEmpty) {
      buffer.writeln('${AppConstants.bankShortName} نامطابق:');
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
        '${AppConstants.varangarShortName} نامطابق: ${PersianNumberFormatter.formatNumber(result.totalUnmatchedPayments)}');
    buffer.writeln(
        '${AppConstants.bankShortName} نامطابق: ${PersianNumberFormatter.formatNumber(result.totalUnmatchedReceivables)}');
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
        /* Font definitions with local file references */
        @font-face {
            font-family: 'Vazirmatn';
            src: url('./Vazirmatn-Regular.ttf') format('truetype');
            font-weight: normal;
            font-style: normal;
            font-display: swap;
        }
        
        @font-face {
            font-family: 'Vazirmatn';
            src: url('./Vazirmatn-Bold.ttf') format('truetype');
            font-weight: bold;
            font-style: normal;
            font-display: swap;
        }
        
        @font-face {
            font-family: 'Vazirmatn';
            src: url('./Vazirmatn-Medium.ttf') format('truetype');
            font-weight: 500;
            font-style: normal;
            font-display: swap;
        }
        
        /* Primary font stack optimized for Persian text */
        body {
            font-family: 'Vazirmatn', 'Segoe UI', 'Tahoma', 'Arial Unicode MS', 'Arial', sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f8f9fa;
            direction: rtl;
            font-size: 14px;
            line-height: 1.6;
        }
        
        /* Ensure Persian text renders properly */
        h1, h2, h3, h4, h5, h6, p, span, div, th, td {
            font-family: inherit;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            margin: 0 0 10px 0;
            font-size: 28px;
            font-weight: 700;
        }
        
        .header-info {
            display: flex;
            justify-content: space-around;
            margin-top: 20px;
            flex-wrap: wrap;
        }
        
        .header-item {
            text-align: center;
            margin: 10px;
        }
        
        .header-item strong {
            display: block;
            font-size: 16px;
            margin-bottom: 5px;
        }
        
        .content {
            padding: 30px;
        }
        
        .section {
            margin-bottom: 40px;
        }
        
        .section-title {
            color: #6366f1;
            font-size: 20px;
            font-weight: 700;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 3px solid #6366f1;
            display: flex;
            align-items: center;
        }
        
        .section-title::before {
            content: '';
            width: 8px;
            height: 20px;
            background-color: #6366f1;
            margin-left: 12px;
            border-radius: 4px;
        }
        
        .excel-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
            background-color: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }
        
        .excel-table th {
            background-color: #f8f9fa;
            color: #374151;
            font-weight: 600;
            padding: 16px 12px;
            text-align: center;
            border: 1px solid #e5e7eb;
            font-size: 14px;
        }
        
        .excel-table td {
            padding: 12px;
            text-align: center;
            border: 1px solid #e5e7eb;
            vertical-align: middle;
        }
        
        .excel-table tr:nth-child(even) {
            background-color: #f9fafb;
        }
        
        .excel-table tr:hover {
            background-color: #f3f4f6;
        }
        
        .match-row {
            background-color: #ecfdf5;
            border-left: 4px solid #10b981;
        }
        
        .combination-row {
            background-color: #eff6ff;
            border-left: 4px solid #3b82f6;
        }
        
        .unmatched-row {
            background-color: #fef3c7;
            border-left: 4px solid #f59e0b;
        }
        
        .amount-cell {
            font-weight: 600;
            color: #059669;
        }
        
        .row-number {
            background-color: #f3f4f6;
            font-weight: 600;
            color: #374151;
            border-radius: 4px;
            padding: 4px 8px;
            font-size: 12px;
        }
        
        .status-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .status-exact {
            background-color: #d1fae5;
            color: #065f46;
        }
        
        .status-combination {
            background-color: #dbeafe;
            color: #1e40af;
        }
        
        .status-unmatched {
            background-color: #fef3c7;
            color: #92400e;
        }
        
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }
        
        .summary-card {
            background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
            color: white;
            padding: 20px;
            border-radius: 12px;
            text-align: center;
            box-shadow: 0 4px 15px rgba(99, 102, 241, 0.3);
        }
        
        .summary-card h3 {
            margin: 0 0 15px 0;
            font-size: 18px;
            font-weight: 600;
        }
        
        .summary-number {
            font-size: 32px;
            font-weight: 700;
            margin-bottom: 5px;
        }
        
        .summary-amount {
            font-size: 16px;
            opacity: 0.9;
        }
        
        .footer {
            background-color: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #6b7280;
            border-top: 1px solid #e5e7eb;
        }
        
        @media print {
            body { 
                background-color: white; 
                margin: 0;
                padding: 10px;
            }
            .container { 
                box-shadow: none; 
                border: 1px solid #e5e7eb;
            }
            .excel-table {
                box-shadow: none;
                border: 1px solid #000;
            }
            .excel-table th,
            .excel-table td {
                border: 1px solid #000;
            }
        }
        
        @media screen and (max-width: 768px) {
            .header-info {
                flex-direction: column;
            }
            .excel-table {
                font-size: 12px;
            }
            .excel-table th,
            .excel-table td {
                padding: 8px 6px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>گزارش تطبیق مبالغ</h1>
            <p>سیستم تطبیق خودکار فاکتورهای ورانگر و تراکنش‌های بانک</p>
            <div class="header-info">
                <div class="header-item">
                    <strong>تاریخ گزارش</strong>
                    <span>${DateTime.now().toLocal().toString().split(' ')[0]}</span>
                </div>
                <div class="header-item">
                    <strong>زمان پردازش</strong>
                    <span>${PersianNumberFormatter.formatNumber(result.processingTime.inMilliseconds)} میلی‌ثانیه</span>
                </div>
                <div class="header-item">
                    <strong>تعداد کل تطبیق‌ها</strong>
                    <span>${PersianNumberFormatter.formatNumber(result.totalExactMatches + result.combinationMatches.where((m) => m.selectedOptionIndex >= 0).length)}</span>
                </div>
            </div>
        </div>

        <div class="content">
            <!-- Summary Section - Moved to top -->
            <div class="summary-grid">
                <div class="summary-card">
                    <h3>تطبیق‌های دقیق</h3>
                    <div class="summary-number">${PersianNumberFormatter.formatNumber(result.totalExactMatches)}</div>
                    <div class="summary-amount">${PersianNumberFormatter.formatCurrency(result.exactMatches.fold(0.0, (sum, match) => sum + match.amount))}</div>
                </div>
                
                <div class="summary-card">
                    <h3>تطبیق‌های ترکیبی</h3>
                    <div class="summary-number">${PersianNumberFormatter.formatNumber(result.combinationMatches.where((match) => match.selectedOptionIndex >= 0).length)}</div>
                    <div class="summary-amount">${PersianNumberFormatter.formatCurrency(result.combinationMatches.where((match) => match.selectedOptionIndex >= 0).fold(0.0, (sum, match) => sum + match.options[match.selectedOptionIndex].totalAmount))}</div>
                </div>
                
                <div class="summary-card">
                    <h3>ورانگر نامطابق</h3>
                    <div class="summary-number">${PersianNumberFormatter.formatNumber(result.totalUnmatchedPayments)}</div>
                    <div class="summary-amount">${PersianNumberFormatter.formatCurrency(result.unmatchedPayments.fold(0.0, (sum, payment) => sum + payment.amount))}</div>
                </div>
                
                <div class="summary-card">
                    <h3>بانک نامطابق</h3>
                    <div class="summary-number">${PersianNumberFormatter.formatNumber(result.totalUnmatchedReceivables)}</div>
                    <div class="summary-amount">${PersianNumberFormatter.formatCurrency(result.unmatchedReceivables.fold(0.0, (sum, receivable) => sum + receivable.amount))}</div>
                </div>
            </div>

            <!-- Exact Matches Section -->
            ${result.exactMatches.isNotEmpty ? '''
            <div class="section">
                <div class="section-title">تطبیق‌های دقیق</div>
                <table class="excel-table">
                    <thead>
                        <tr>
                            <th>وضعیت</th>
                            <th>ردیف ورانگر</th>
                            <th>مبلغ ورانگر</th>
                            <th>ردیف بانک</th>
                            <th>مبلغ بانک</th>
                            <th>نوع تطبیق</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${result.exactMatches.map((match) => '''
                            <tr class="match-row">
                                <td><span class="status-badge status-exact">تطبیق</span></td>
                                <td><span class="row-number">${PersianNumberFormatter.formatNumber(match.payment.rowNumber)}</span></td>
                                <td class="amount-cell">${PersianNumberFormatter.formatCurrency(match.payment.amount)}</td>
                                <td><span class="row-number">${PersianNumberFormatter.formatNumber(match.receivable.rowNumber)}</span></td>
                                <td class="amount-cell">${PersianNumberFormatter.formatCurrency(match.receivable.amount)}</td>
                                <td>تطبیق دقیق</td>
                            </tr>
                        ''').join('')}
                    </tbody>
                </table>
            </div>
            ''' : ''}

            <!-- Combination Matches Section -->
            ${result.combinationMatches.where((match) => match.selectedOptionIndex >= 0).isNotEmpty ? '''
            <div class="section">
                <div class="section-title">تطبیق‌های ترکیبی</div>
                <table class="excel-table">
                    <thead>
                        <tr>
                            <th>وضعیت</th>
                            <th>ردیف ورانگر</th>
                            <th>مبلغ ورانگر</th>
                            <th>ردیف‌های بانک</th>
                            <th>مبالغ بانک</th>
                            <th>مجموع ترکیب</th>
                            <th>نوع تطبیق</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${result.combinationMatches.where((match) => match.selectedOptionIndex >= 0).map((match) {
            final selectedOption = match.options[match.selectedOptionIndex];
            final bankRows = selectedOption.receivables
                .map((r) => PersianNumberFormatter.formatNumber(r.rowNumber))
                .join(', ');
            final bankAmounts = selectedOption.receivables
                .map((r) => PersianNumberFormatter.formatCurrency(r.amount))
                .join(', ');
            return '''
                                <tr class="combination-row">
                                    <td><span class="status-badge status-combination">ترکیب</span></td>
                                    <td><span class="row-number">${PersianNumberFormatter.formatNumber(match.payment.rowNumber)}</span></td>
                                    <td class="amount-cell">${PersianNumberFormatter.formatCurrency(match.payment.amount)}</td>
                                    <td><span class="row-number">$bankRows</span></td>
                                    <td class="amount-cell">$bankAmounts</td>
                                    <td class="amount-cell">${PersianNumberFormatter.formatCurrency(selectedOption.totalAmount)}</td>
                                    <td>${selectedOption.isTerminalBased ? 'ترکیب ترمینال' : 'ترکیب معمولی'}</td>
                                </tr>
                            ''';
          }).join('')}
                    </tbody>
                </table>
            </div>
            ''' : ''}

            <!-- Unmatched Section -->
            <div class="section">
                <div class="section-title">رکوردهای نامطابق</div>
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                    <!-- Unmatched Varanegar -->
                    ${result.unmatchedPayments.isNotEmpty ? '''
                    <div>
                        <h4 style="color: #f59e0b; margin-bottom: 15px;">ورانگر نامطابق</h4>
                        <table class="excel-table">
                            <thead>
                                <tr>
                                    <th>ردیف</th>
                                    <th>مبلغ</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${result.unmatchedPayments.map((payment) => '''
                                    <tr class="unmatched-row">
                                        <td><span class="row-number">${PersianNumberFormatter.formatNumber(payment.rowNumber)}</span></td>
                                        <td class="amount-cell">${PersianNumberFormatter.formatCurrency(payment.amount)}</td>
                                    </tr>
                                ''').join('')}
                            </tbody>
                        </table>
                    </div>
                    ''' : '<div><h4 style="color: #10b981;">ورانگر نامطابق</h4><p>همه رکوردها تطبیق شده‌اند</p></div>'}
                    
                    <!-- Unmatched Bank -->
                    ${result.unmatchedReceivables.isNotEmpty ? '''
                    <div>
                        <h4 style="color: #f59e0b; margin-bottom: 15px;">بانک نامطابق</h4>
                        <table class="excel-table">
                            <thead>
                                <tr>
                                    <th>ردیف</th>
                                    <th>مبلغ</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${result.unmatchedReceivables.map((receivable) => '''
                                    <tr class="unmatched-row">
                                        <td><span class="row-number">${PersianNumberFormatter.formatNumber(receivable.rowNumber)}</span></td>
                                        <td class="amount-cell">${PersianNumberFormatter.formatCurrency(receivable.amount)}</td>
                                    </tr>
                                ''').join('')}
                            </tbody>
                        </table>
                    </div>
                    ''' : '<div><h4 style="color: #10b981;">بانک نامطابق</h4><p>همه رکوردها تطبیق شده‌اند</p></div>'}
                </div>
            </div>
        </div>

        <div class="footer">
            <p>گزارش تولید شده توسط سیستم مچیفای دسکتاپ</p>
            <p>تاریخ تولید: ${DateTime.now().toLocal()}</p>
        </div>
    </div>
</body>
</html>
    ''';
  }
}
