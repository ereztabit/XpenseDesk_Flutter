import 'company_module.dart';
import 'payment_status.dart';

/// Immutable filter state for the Payments Report.
///
/// All fields are ANDed server-side. Null means "not filtered" — except
/// [status], where null maps to "All" (the `paymentStatus` param is omitted).
class PaymentsFilter {
  final PaymentStatus? status;
  final String? userId;
  final String? cycleId;
  final DateTime? approvedFrom;
  final DateTime? approvedTo;
  final DateTime? processedFrom;
  final DateTime? processedTo;

  /// FS-1020 PC-8: Monthly / PettyCash; null = every type.
  final CompanyModuleKey? sheetType;

  const PaymentsFilter({
    this.status,
    this.userId,
    this.cycleId,
    this.approvedFrom,
    this.approvedTo,
    this.processedFrom,
    this.processedTo,
    this.sheetType,
  });

  /// The landing state: every status, nothing filtered (PC-9, D41). The
  /// dashboard cards still open on Pending by passing it explicitly.
  static const defaults = PaymentsFilter();

  /// The manager's "Payments" entry: what still has to be settled.
  static const pending = PaymentsFilter(status: PaymentStatus.awaitingPayment);

  static const Object _unset = Object();

  /// copyWith that can also CLEAR fields (pass null explicitly).
  PaymentsFilter copyWith({
    Object? status = _unset,
    Object? userId = _unset,
    Object? cycleId = _unset,
    Object? approvedFrom = _unset,
    Object? approvedTo = _unset,
    Object? processedFrom = _unset,
    Object? processedTo = _unset,
    Object? sheetType = _unset,
  }) {
    return PaymentsFilter(
      status:
          identical(status, _unset) ? this.status : status as PaymentStatus?,
      userId: identical(userId, _unset) ? this.userId : userId as String?,
      cycleId: identical(cycleId, _unset) ? this.cycleId : cycleId as String?,
      approvedFrom: identical(approvedFrom, _unset)
          ? this.approvedFrom
          : approvedFrom as DateTime?,
      approvedTo: identical(approvedTo, _unset)
          ? this.approvedTo
          : approvedTo as DateTime?,
      processedFrom: identical(processedFrom, _unset)
          ? this.processedFrom
          : processedFrom as DateTime?,
      processedTo: identical(processedTo, _unset)
          ? this.processedTo
          : processedTo as DateTime?,
      sheetType: identical(sheetType, _unset)
          ? this.sheetType
          : sheetType as CompanyModuleKey?,
    );
  }

  /// Count of active filters — drives the mobile tune-icon badge. The status
  /// counts whenever set (so the default landing state shows "1", matching
  /// the approved mock); each date range counts once.
  int get activeCount {
    var count = 0;
    if (status != null) count++;
    if (userId != null) count++;
    if (cycleId != null) count++;
    if (approvedFrom != null || approvedTo != null) count++;
    if (processedFrom != null || processedTo != null) count++;
    if (sheetType != null) count++;
    return count;
  }

  /// `yyyy-MM-dd` without DateFormat (CR rule: no direct DateFormat usage).
  static String _apiDate(DateTime d) =>
      d.toIso8601String().split('T').first;

  /// Query params for `GET /api/payments` and body for the filtered export.
  /// Omitted keys mean "no filter" server-side.
  /// PC-9: the screen always lists "No payment" sheets too
  /// (`includeNoPayment`); the export body sends it as a JSON bool.
  Map<String, String> toQueryParams({int? page, int? pageSize}) {
    return {
      'includeNoPayment': 'true',
      if (status != null) 'paymentStatus': '${status!.queryId}',
      'userId': ?userId,
      'cycleId': ?cycleId,
      if (approvedFrom != null) 'approvedFrom': _apiDate(approvedFrom!),
      if (approvedTo != null) 'approvedTo': _apiDate(approvedTo!),
      if (processedFrom != null) 'processedFrom': _apiDate(processedFrom!),
      if (processedTo != null) 'processedTo': _apiDate(processedTo!),
      if (sheetType != null) 'sheetType': sheetType!.apiValue,
      'page': ?page?.toString(),
      'pageSize': ?pageSize?.toString(),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is PaymentsFilter &&
      other.status == status &&
      other.userId == userId &&
      other.cycleId == cycleId &&
      other.approvedFrom == approvedFrom &&
      other.approvedTo == approvedTo &&
      other.processedFrom == processedFrom &&
      other.processedTo == processedTo &&
      other.sheetType == sheetType;

  @override
  int get hashCode => Object.hash(status, userId, cycleId, approvedFrom,
      approvedTo, processedFrom, processedTo, sheetType);
}
