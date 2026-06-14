import 'dart:typed_data';

import '../models/paged_payments.dart';
import '../models/payment_status.dart';
import '../models/payments_filter.dart';
import '../models/payments_summary.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'expense_service.dart'
    show SubscriptionRequiredException, ExpenseSheetNotFoundException;

/// Exception thrown when payment operations fail.
class PaymentException implements Exception {
  final String message;
  final String? errorCode;
  const PaymentException(this.message, {this.errorCode});

  @override
  String toString() => message;
}

/// Thrown when a /process batch contains a sheet that is no longer
/// AwaitingPayment (server errorCode `PaymentSheetNotAwaiting`, all-or-nothing
/// — nothing was updated). [offendingIds] lists the conflicting sheets so the
/// UI can refetch and highlight them.
class PaymentSheetNotAwaitingException implements Exception {
  final List<String> offendingIds;
  const PaymentSheetNotAwaitingException(this.offendingIds);
}

/// Thrown when an update/revert targets a sheet that is not Processed
/// (server errorCode `PaymentSheetNotProcessed`).
class PaymentSheetNotProcessedException implements Exception {
  const PaymentSheetNotProcessedException();
}

/// Thrown when a write/export-selected call carries more than 100 sheet ids
/// (server errorCode `PaymentBulkLimitExceeded`). The UI guards this
/// client-side too.
class PaymentBulkLimitExceededException implements Exception {
  const PaymentBulkLimitExceededException();
}

/// Service for the XpenseDesk Payments API. All endpoints are manager-only —
/// the server returns 403 for any other role.
class PaymentService {
  final ApiService _apiService;
  final AuthService _authService;

  /// Server-side cap on ids per write/export-selected call.
  static const int maxBatchSize = 100;

  PaymentService({ApiService? apiService, AuthService? authService})
      : _apiService = apiService ?? ApiService(),
        _authService = authService ?? AuthService();

  void _validateSessionToken(String? sessionToken) {
    if (sessionToken == null || sessionToken.isEmpty) {
      throw const PaymentException('No session token found');
    }
  }

  void _validateResponse(
    Map<String, dynamic> response,
    String defaultErrorMessage,
  ) {
    final success = response['success'] as bool? ?? false;
    if (success) return;

    final message = response['message'] as String? ?? defaultErrorMessage;
    final errorCode = response['errorCode'] as String?;
    switch (errorCode) {
      case 'PaymentSheetNotAwaiting':
        throw PaymentSheetNotAwaitingException(_idsFromData(response));
      case 'PaymentSheetNotProcessed':
        throw const PaymentSheetNotProcessedException();
      case 'PaymentBulkLimitExceeded':
        throw const PaymentBulkLimitExceededException();
      case 'SubscriptionRequired':
        throw const SubscriptionRequiredException();
      case 'ExpenseSheetNotFound':
        throw const ExpenseSheetNotFoundException();
    }
    throw PaymentException(message, errorCode: errorCode);
  }

  /// The PaymentSheetNotAwaiting error lists the offending sheet ids in
  /// `data`. Parsed defensively — an empty list still triggers the
  /// refetch-and-retry UX.
  static List<String> _idsFromData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) return data.whereType<String>().toList();
    if (data is Map<String, dynamic>) {
      final ids = data['expenseSheetIds'] ?? data['offendingIds'];
      if (ids is List) return ids.whereType<String>().toList();
    }
    return const [];
  }

  static PaymentsSummary? _summaryFromData(Map<String, dynamic>? data) {
    final summaryJson = data?['paymentsSummary'];
    if (summaryJson is Map<String, dynamic>) {
      return PaymentsSummary.fromJson(summaryJson);
    }
    return null;
  }

  static String _apiDate(DateTime d) => d.toIso8601String().split('T').first;

  /// Fetch the payments report page for [filter].
  Future<PagedPayments> getPayments(
    PaymentsFilter filter, {
    int page = 1,
    int pageSize = 100,
  }) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.get(
      '/api/payments',
      authToken: sessionToken,
      queryParams: filter.toQueryParams(page: page, pageSize: pageSize),
    );

    _validateResponse(response, 'Failed to load payments');

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) return PagedPayments.empty;
    return PagedPayments.fromJson(data);
  }

  /// Mark a batch of AwaitingPayment sheets as Processed. All-or-nothing —
  /// on failure nothing was updated.
  ///
  /// Returns the processed count plus the fresh [PaymentsSummary] for the
  /// dashboard card (never refetch /api/company for it).
  Future<({int processedCount, PaymentsSummary? summary})> processPayments({
    required List<String> expenseSheetIds,
    required DateTime processedDate,
    String? note,
  }) async {
    if (expenseSheetIds.length > maxBatchSize) {
      throw const PaymentBulkLimitExceededException();
    }
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/payments/process',
      {
        'expenseSheetIds': expenseSheetIds,
        'processedDate': _apiDate(processedDate),
        if (note != null && note.isNotEmpty) 'note': note,
      },
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to process payments');

    final data = response['data'] as Map<String, dynamic>?;
    return (
      processedCount:
          (data?['processedCount'] as num?)?.toInt() ?? expenseSheetIds.length,
      summary: _summaryFromData(data),
    );
  }

  /// Edit a Processed sheet's details (status stays Processed, [processedDate]
  /// required) or revert it to Awaiting (status AwaitingPayment, other fields
  /// ignored — the server clears them).
  Future<PaymentsSummary?> updatePayment(
    String expenseSheetId, {
    required PaymentStatus status,
    DateTime? processedDate,
    String? note,
  }) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.put(
      '/api/payments/$expenseSheetId',
      _updateBody(status, processedDate: processedDate, note: note),
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to update payment');
    return _summaryFromData(response['data'] as Map<String, dynamic>?);
  }

  /// Bulk variant of [updatePayment] — all-or-nothing like /process.
  Future<PaymentsSummary?> bulkUpdatePayments({
    required List<String> expenseSheetIds,
    required PaymentStatus status,
    DateTime? processedDate,
    String? note,
  }) async {
    if (expenseSheetIds.length > maxBatchSize) {
      throw const PaymentBulkLimitExceededException();
    }
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/payments/bulk-update',
      {
        'expenseSheetIds': expenseSheetIds,
        ..._updateBody(status, processedDate: processedDate, note: note),
      },
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to update payments');
    return _summaryFromData(response['data'] as Map<String, dynamic>?);
  }

  /// Routes a single sheet's status change to the right endpoint, used by the
  /// per-row edit dialog:
  ///  - awaiting  -> processed: /process (mark processed)
  ///  - processed -> processed: PUT (edit details)
  ///  - processed -> awaiting: PUT with AwaitingPayment (revert)
  /// Returns the fresh [PaymentsSummary] from the write response.
  Future<PaymentsSummary?> applyStatusChange({
    required String expenseSheetId,
    required PaymentStatus from,
    required PaymentStatus to,
    DateTime? processedDate,
    String? note,
  }) async {
    if (from == PaymentStatus.awaitingPayment &&
        to == PaymentStatus.processed) {
      final result = await processPayments(
        expenseSheetIds: [expenseSheetId],
        processedDate: processedDate!,
        note: note,
      );
      return result.summary;
    }
    if (to == PaymentStatus.processed) {
      return updatePayment(
        expenseSheetId,
        status: PaymentStatus.processed,
        processedDate: processedDate,
        note: note,
      );
    }
    return updatePayment(expenseSheetId,
        status: PaymentStatus.awaitingPayment);
  }

  static Map<String, dynamic> _updateBody(
    PaymentStatus status, {
    DateTime? processedDate,
    String? note,
  }) {
    return {
      'paymentStatus': status.wireName,
      if (processedDate != null) 'processedDate': _apiDate(processedDate),
      'note': ?note,
    };
  }

  /// Export the FULL filtered set as .xlsx — the server applies [filter];
  /// never page-walk to build an export.
  Future<Uint8List> exportPaymentsReport(PaymentsFilter filter) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    return _apiService.postBinary(
      '/api/reports/export-payments-report',
      filter.toQueryParams(),
      authToken: sessionToken,
    );
  }

  /// Export the selected sheets as .xlsx (max [maxBatchSize] ids).
  Future<Uint8List> exportSelectedPayments(
      List<String> expenseSheetIds) async {
    if (expenseSheetIds.length > maxBatchSize) {
      throw const PaymentBulkLimitExceededException();
    }
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    return _apiService.postBinary(
      '/api/reports/bulk-export-payments-report',
      {'expenseSheetIds': expenseSheetIds},
      authToken: sessionToken,
    );
  }
}
