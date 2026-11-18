/// FS-1019 — the platform-admin Currencies module's data.
///
/// Mirrors `GET /api/admin/currencies` and
/// `GET /api/admin/currencies/sync-runs/{id}` (docs/api-guides/
/// currency-admin-api-guide.md). Status strings are the server's; an
/// unrecognised one maps to [AdminCurrencyStatus.unknown] and is shown verbatim
/// rather than guessed.
library;

enum AdminCurrencyStatus { ok, behind, failed, noData, unknown }

AdminCurrencyStatus parseAdminCurrencyStatus(String? value) => switch (value) {
      'Ok' => AdminCurrencyStatus.ok,
      'Behind' => AdminCurrencyStatus.behind,
      'Failed' => AdminCurrencyStatus.failed,
      'NoData' => AdminCurrencyStatus.noData,
      _ => AdminCurrencyStatus.unknown,
    };

enum AdminCurrencyRunStatus { ok, problems, failed, running, unknown }

AdminCurrencyRunStatus parseAdminCurrencyRunStatus(String? value) =>
    switch (value) {
      'Ok' => AdminCurrencyRunStatus.ok,
      'Problems' => AdminCurrencyRunStatus.problems,
      'Failed' => AdminCurrencyRunStatus.failed,
      'Running' => AdminCurrencyRunStatus.running,
      _ => AdminCurrencyRunStatus.unknown,
    };

DateTime? _date(Object? v) =>
    v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

double? _num(Object? v) => v is num ? v.toDouble() : null;

/// One tracked currency in the status table.
class AdminCurrencyRow {
  const AdminCurrencyRow({
    required this.currencyCode,
    required this.currencyName,
    required this.currencySymbol,
    required this.status,
    required this.rawStatus,
    required this.rateCount,
    this.firstRateDate,
    this.lastRateDate,
    this.lastRate,
    this.lastUnitMult,
    this.lastCheckedAt,
    this.lastError,
    this.lastSyncRunId,
  });

  final String currencyCode;
  final String currencyName;
  final String currencySymbol;
  final AdminCurrencyStatus status;
  final String rawStatus;
  final int rateCount;
  final DateTime? firstRateDate;
  final DateTime? lastRateDate;
  final double? lastRate;
  final int? lastUnitMult;

  /// UTC. The last time the sync wrote this currency's newest rows.
  final DateTime? lastCheckedAt;
  final String? lastError;
  final int? lastSyncRunId;

  factory AdminCurrencyRow.fromJson(Map<String, dynamic> json) =>
      AdminCurrencyRow(
        currencyCode: json['currencyCode'] as String? ?? '',
        currencyName: json['currencyName'] as String? ?? '',
        currencySymbol: json['currencySymbol'] as String? ?? '',
        status: parseAdminCurrencyStatus(json['status'] as String?),
        rawStatus: json['status'] as String? ?? '',
        rateCount: (json['rateCount'] as num?)?.toInt() ?? 0,
        firstRateDate: _date(json['firstRateDate']),
        lastRateDate: _date(json['lastRateDate']),
        lastRate: _num(json['lastRate']),
        lastUnitMult: (json['lastUnitMult'] as num?)?.toInt(),
        lastCheckedAt: _date(json['lastCheckedAt']),
        lastError: json['lastError'] as String?,
        lastSyncRunId: (json['lastSyncRunId'] as num?)?.toInt(),
      );
}

/// One sync run, as listed under "Recent syncs" and as the run detail's header.
class AdminCurrencySyncRunSummary {
  const AdminCurrencySyncRunSummary({
    required this.syncRunId,
    required this.triggerType,
    required this.status,
    required this.rawStatus,
    required this.startedAt,
    required this.isQa,
    required this.currencyCount,
    required this.problemCount,
    required this.rowsInserted,
    required this.rowsRevised,
    this.triggeredByName,
    this.finishedAt,
    this.referenceRateDate,
    this.emailSubject,
    this.error,
  });

  final int syncRunId;

  /// `Scheduled` or `Manual`.
  final String triggerType;
  final String? triggeredByName;
  final AdminCurrencyRunStatus status;
  final String rawStatus;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final bool isQa;
  final DateTime? referenceRateDate;
  final int currencyCount;
  final int problemCount;
  final int rowsInserted;
  final int rowsRevised;
  final String? emailSubject;
  final String? error;

  bool get isManual => triggerType == 'Manual';

  factory AdminCurrencySyncRunSummary.fromJson(Map<String, dynamic> json) =>
      AdminCurrencySyncRunSummary(
        syncRunId: (json['syncRunId'] as num?)?.toInt() ?? 0,
        triggerType: json['triggerType'] as String? ?? '',
        triggeredByName: json['triggeredByName'] as String?,
        status: parseAdminCurrencyRunStatus(json['status'] as String?),
        rawStatus: json['status'] as String? ?? '',
        startedAt: _date(json['startedAt']) ?? DateTime.now().toUtc(),
        finishedAt: _date(json['finishedAt']),
        isQa: json['isQa'] as bool? ?? false,
        referenceRateDate: _date(json['referenceRateDate']),
        currencyCount: (json['currencyCount'] as num?)?.toInt() ?? 0,
        problemCount: (json['problemCount'] as num?)?.toInt() ?? 0,
        rowsInserted: (json['rowsInserted'] as num?)?.toInt() ?? 0,
        rowsRevised: (json['rowsRevised'] as num?)?.toInt() ?? 0,
        emailSubject: json['emailSubject'] as String?,
        error: json['error'] as String?,
      );
}

/// One currency's line in a sync run.
class AdminCurrencySyncItem {
  const AdminCurrencySyncItem({
    required this.currencyCode,
    required this.status,
    required this.rawStatus,
    required this.rowsFetched,
    required this.rowsRejected,
    required this.attempts,
    this.currencyName,
    this.fromDate,
    this.toDate,
    this.newestRateDate,
    this.newestRate,
    this.unitMult,
    this.error,
  });

  final String currencyCode;
  final String? currencyName;
  final AdminCurrencyStatus status;
  final String rawStatus;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int rowsFetched;
  final int rowsRejected;
  final int attempts;
  final DateTime? newestRateDate;
  final double? newestRate;
  final int? unitMult;
  final String? error;

  factory AdminCurrencySyncItem.fromJson(Map<String, dynamic> json) =>
      AdminCurrencySyncItem(
        currencyCode: json['currencyCode'] as String? ?? '',
        currencyName: json['currencyName'] as String?,
        status: parseAdminCurrencyStatus(json['status'] as String?),
        rawStatus: json['status'] as String? ?? '',
        fromDate: _date(json['fromDate']),
        toDate: _date(json['toDate']),
        rowsFetched: (json['rowsFetched'] as num?)?.toInt() ?? 0,
        rowsRejected: (json['rowsRejected'] as num?)?.toInt() ?? 0,
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        newestRateDate: _date(json['newestRateDate']),
        newestRate: _num(json['newestRate']),
        unitMult: (json['unitMult'] as num?)?.toInt(),
        error: json['error'] as String?,
      );
}

class AdminCurrencySyncRun {
  const AdminCurrencySyncRun({required this.summary, required this.items});

  final AdminCurrencySyncRunSummary summary;
  final List<AdminCurrencySyncItem> items;

  factory AdminCurrencySyncRun.fromJson(Map<String, dynamic> json) =>
      AdminCurrencySyncRun(
        summary: AdminCurrencySyncRunSummary.fromJson(json),
        items: (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AdminCurrencySyncItem.fromJson)
            .toList(),
      );
}

/// `GET /api/admin/currencies`.
class AdminCurrencyOverview {
  const AdminCurrencyOverview({
    required this.currencies,
    required this.recentRuns,
    this.referenceRateDate,
  });

  /// Newest Bank of Israel date across all tracked currencies.
  final DateTime? referenceRateDate;
  final List<AdminCurrencyRow> currencies;
  final List<AdminCurrencySyncRunSummary> recentRuns;

  factory AdminCurrencyOverview.fromJson(Map<String, dynamic> json) =>
      AdminCurrencyOverview(
        referenceRateDate: _date(json['referenceRateDate']),
        currencies: (json['currencies'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AdminCurrencyRow.fromJson)
            .toList(),
        recentRuns: (json['recentRuns'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AdminCurrencySyncRunSummary.fromJson)
            .toList(),
      );
}
