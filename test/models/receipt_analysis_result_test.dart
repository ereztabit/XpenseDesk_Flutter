import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/receipt_analysis_result.dart';

/// These two getters decide what the New Expense screen shows after a scan:
/// the plain form, the editable panel with the gap flagged, or the read-only
/// detected-details summary.
void main() {
  group('hasNoDetectedFields', () {
    test('is true when the scan succeeded but read nothing', () {
      const result = ReceiptAnalysisResult();
      expect(result.hasNoDetectedFields, isTrue);
    });

    test('treats blank strings as nothing', () {
      const result = ReceiptAnalysisResult(
        merchantName: '   ',
        expenseDate: '',
        receiptNumber: '  ',
      );
      expect(result.hasNoDetectedFields, isTrue);
    });

    test('is false when any single field was read', () {
      const result = ReceiptAnalysisResult(merchantName: 'CITY PARKING LTD');
      expect(result.hasNoDetectedFields, isFalse);
    });

    test('ignores fields the user never has to see', () {
      const result = ReceiptAnalysisResult(categoryId: 5, imageUrl: 'x.png');
      expect(result.hasNoDetectedFields, isTrue);
    });
  });

  group('isMissingMandatoryFields', () {
    test('is false only when both amount and a parsable date are present', () {
      const result = ReceiptAnalysisResult(
        amount: 45.0,
        expenseDate: '2026-06-08',
      );
      expect(result.isMissingMandatoryFields, isFalse);
    });

    test('is true when the amount is missing but everything else was read', () {
      const result = ReceiptAnalysisResult(
        expenseDate: '2026-06-08',
        merchantName: 'CITY PARKING LTD',
        receiptNumber: '99120',
      );
      expect(result.isMissingMandatoryFields, isTrue);
    });

    test('is true when the date is missing', () {
      const result = ReceiptAnalysisResult(amount: 45.0);
      expect(result.isMissingMandatoryFields, isTrue);
    });

    test('is true when the date is present but unparsable', () {
      const result = ReceiptAnalysisResult(
        amount: 45.0,
        expenseDate: '08/06/2026',
      );
      expect(result.isMissingMandatoryFields, isTrue);
    });

    test('a zero amount counts as read', () {
      const result = ReceiptAnalysisResult(
        amount: 0,
        expenseDate: '2026-06-08',
      );
      expect(result.isMissingMandatoryFields, isFalse);
    });
  });
}
