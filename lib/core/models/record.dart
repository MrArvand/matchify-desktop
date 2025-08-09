class Record {
  final int rowNumber;
  final double amount;
  final String originalAmount;
  final String? refCode;
  final Map<String, dynamic> additionalData;

  Record({
    required this.rowNumber,
    required this.amount,
    required this.originalAmount,
    this.refCode,
    this.additionalData = const {},
  });

  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      rowNumber: map['rowNumber'] ?? 0,
      amount: (map['amount'] ?? 0.0).toDouble(),
      originalAmount: map['originalAmount'] ?? '',
      refCode: map['refCode'],
      additionalData: Map<String, dynamic>.from(map['additionalData'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rowNumber': rowNumber,
      'amount': amount,
      'originalAmount': originalAmount,
      'refCode': refCode,
      'additionalData': additionalData,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Record &&
        other.rowNumber == rowNumber &&
        other.amount == amount &&
        other.originalAmount == originalAmount;
  }

  @override
  int get hashCode {
    return rowNumber.hashCode ^ amount.hashCode ^ originalAmount.hashCode;
  }

  @override
  String toString() {
    return 'Record(rowNumber: $rowNumber, amount: $amount, originalAmount: $originalAmount)';
  }
}

class PaymentRecord extends Record {
  PaymentRecord({
    required super.rowNumber,
    required super.amount,
    required super.originalAmount,
    super.additionalData,
  });

  factory PaymentRecord.fromRecord(Record record) {
    return PaymentRecord(
      rowNumber: record.rowNumber,
      amount: record.amount,
      originalAmount: record.originalAmount,
      additionalData: record.additionalData,
    );
  }
}

class ReceivableRecord extends Record {
  ReceivableRecord({
    required super.rowNumber,
    required super.amount,
    required super.originalAmount,
    super.additionalData,
  });

  factory ReceivableRecord.fromRecord(Record record) {
    return ReceivableRecord(
      rowNumber: record.rowNumber,
      amount: record.amount,
      originalAmount: record.originalAmount,
      additionalData: record.additionalData,
    );
  }
}
