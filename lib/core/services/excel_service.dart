import 'dart:io';
import 'package:excel/excel.dart';
import 'package:matchify_desktop/core/models/record.dart';
import 'package:matchify_desktop/core/services/matching_service.dart';

class ExcelService {
  /// Read records from Excel file
  static Future<List<Record>> readRecordsFromFile({
    required String filePath,
    required int amountColumnIndex,
    required int startRow,
    required Function(double) onProgress,
    int? terminalCodeColumnIndex,
  }) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final records = <Record>[];
      final sheet = excel.tables[excel.tables.keys.first];

      if (sheet == null) {
        throw Exception('No sheet found in Excel file');
      }

      final maxRow = sheet.maxRows;
      int processedRows = 0;

      for (int row = startRow; row < maxRow; row++) {
        final rowData = sheet.row(row);

        if (rowData.isEmpty) continue;

        final amountCell = rowData[amountColumnIndex];
        if (amountCell == null) continue;

        final amountStr = amountCell.value?.toString() ?? '';
        if (amountStr.isEmpty) continue;

        final amount = MatchingService.parseAmount(amountStr);
        if (amount <= 0) continue;

        final additionalData = _extractAdditionalData(
          rowData,
          amountColumnIndex,
        );

        // Capture terminal code explicitly if column provided
        if (terminalCodeColumnIndex != null &&
            terminalCodeColumnIndex >= 0 &&
            terminalCodeColumnIndex < rowData.length) {
          final terminalCell = rowData[terminalCodeColumnIndex];
          final terminalValue = terminalCell?.value?.toString();
          if (terminalValue != null && terminalValue.isNotEmpty) {
            additionalData['terminal_code'] = terminalValue;
          }
        }

        records.add(
          Record(
            rowNumber: row + 1, // Excel rows are 1-indexed
            amount: amount,
            originalAmount: amountStr,
            additionalData: additionalData,
          ),
        );

        processedRows++;
        if (processedRows % 100 == 0) {
          onProgress(processedRows / maxRow);
        }
      }

      return records;
    } catch (e) {
      throw Exception('Error reading Excel file: $e');
    }
  }

  /// Extract additional data from row (excluding amount column)
  static Map<String, dynamic> _extractAdditionalData(
    List<Data?> rowData,
    int amountColumnIndex,
  ) {
    final additionalData = <String, dynamic>{};

    for (int i = 0; i < rowData.length; i++) {
      if (i != amountColumnIndex) {
        final cell = rowData[i];
        if (cell != null && cell.value != null) {
          additionalData['col_$i'] = cell.value.toString();
        }
      }
    }

    return additionalData;
  }

  /// Write matching results to Excel file
  static Future<void> writeResultsToExcel({
    required String filePath,
    required Map<String, dynamic> results,
    required String sheetName,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel[sheetName];

      // Write headers
      final headers = [
        'Match Type',
        'Payment Row',
        'Payment Amount',
        'Receivable Rows',
        'Receivable Amounts',
        'Total Amount',
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = headers[i];
      }

      int currentRow = 1;

      // Write exact matches
      final exactMatches = results['exact_matches'] as List;
      for (final match in exactMatches) {
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        )..value = 'Exact Match';
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
        )..value = match['payment_row'];
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow),
        )..value = match['amount'];
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
        )..value = match['receivable_row'];
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
        )..value = match['amount'];
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
        )..value = match['amount'];
        currentRow++;
      }

      // Write combination matches
      final combinationMatches = results['combination_matches'] as List;
      for (final match in combinationMatches) {
        final combinations = match['combinations'] as List;
        for (final combination in combinations) {
          sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
          )..value = 'Combination Match';
          sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
          )..value = match['payment_row'];
          sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow),
          )..value = match['amount'];
          sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
          )..value = (combination['rows'] as List).join(', ');
          sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
          )..value = (combination['amounts'] as List).join(', ');
          sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
          )..value = combination['amounts'].fold(
              0.0,
              (sum, amount) => sum + amount,
            );
          currentRow++;
        }
      }

      // Write unmatched payments
      final unmatchedPayments = results['unmatched_payments'] as List;
      for (final payment in unmatchedPayments) {
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        )..value = 'Unmatched Payment';
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
        )..value = payment['rowNumber'];
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow),
        )..value = payment['amount'];
        currentRow++;
      }

      // Write unmatched receivables
      final unmatchedReceivables = results['unmatched_receivables'] as List;
      for (final receivable in unmatchedReceivables) {
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        )..value = 'Unmatched Receivable';
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
        )..value = receivable['rowNumber'];
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
        )..value = receivable['amount'];
        currentRow++;
      }

      // Auto-fit columns - removed for compatibility with excel 2.1.0
      // for (int i = 0; i < headers.length; i++) {
      //   sheet.setColumnWidth(i, 20.0);
      // }

      // Save file
      final bytes = excel.encode();
      if (bytes != null) {
        await File(filePath).writeAsBytes(bytes);
      }
    } catch (e) {
      throw Exception('Error writing Excel file: $e');
    }
  }

  /// Get column headers from Excel file
  static Future<List<String>> getColumnHeaders(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first];

      if (sheet == null) {
        throw Exception('No sheet found in Excel file');
      }

      final headers = <String>[];
      final headerRow = sheet.row(0);

      for (final cell in headerRow) {
        headers.add(cell?.value?.toString() ?? '');
      }

      return headers;
    } catch (e) {
      throw Exception('Error reading column headers: $e');
    }
  }

  /// Validate Excel file format
  static Future<bool> validateExcelFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      return excel.tables.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
