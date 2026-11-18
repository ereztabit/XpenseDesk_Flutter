/// Payments export file name with a full local timestamp, so every download
/// gets its own name and never replaces an earlier one (owner, 2026-11-18):
/// "payments-report-2026-11-18_20-15-42.xlsx".
String paymentsExportFileName(String base, [DateTime? at]) {
  String two(int n) => n.toString().padLeft(2, '0');
  final t = at ?? DateTime.now();
  return '$base-${t.year}-${two(t.month)}-${two(t.day)}'
      '_${two(t.hour)}-${two(t.minute)}-${two(t.second)}.xlsx';
}
