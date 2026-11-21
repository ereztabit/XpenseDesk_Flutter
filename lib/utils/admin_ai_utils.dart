import '../models/admin_ai_profile.dart';
import '../models/admin_ai_usage.dart';

/// FS-1026 Receipt AI - list rules shared by the screens (no widgets here).
/// docs/backlog/receipt-ai-profiles-spec.md

/// The default profile first, then by its permanent number.
List<AdminAiProfileRow> sortAiProfiles(Iterable<AdminAiProfileRow> rows) {
  final list = rows.toList()
    ..sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return a.aiProfileId.compareTo(b.aiProfileId);
    });
  return list;
}

List<AdminAiProfileRow> visibleAiProfiles(Iterable<AdminAiProfileRow> rows, {required bool showArchived}) =>
    sortAiProfiles(rows.where((r) => showArchived || !r.isArchived));

/// Profiles a company can be moved onto, or a new profile copied from.
List<AdminAiProfileRow> activeAiProfiles(Iterable<AdminAiProfileRow> rows) =>
    sortAiProfiles(rows.where((r) => !r.isArchived));

enum AdminAiProfileStatus { isDefault, inUse, notInUse, archived }

AdminAiProfileStatus aiProfileStatus(AdminAiProfileRow row) {
  if (row.isArchived) return AdminAiProfileStatus.archived;
  if (row.isDefault) return AdminAiProfileStatus.isDefault;
  return row.companyCount > 0 ? AdminAiProfileStatus.inUse : AdminAiProfileStatus.notInUse;
}

/// Why Archive is disabled (null = allowed). The server refuses the same cases.
enum AdminAiArchiveBlock { isDefault, hasCompanies }

AdminAiArchiveBlock? aiArchiveBlock(AdminAiProfileRow row) {
  if (row.isDefault) return AdminAiArchiveBlock.isDefault;
  if (row.companyCount > 0) return AdminAiArchiveBlock.hasCompanies;
  return null;
}

bool canSetAiDefault(AdminAiProfileRow row) => !row.isDefault && !row.isArchived;

/// Verified / (Verified + Corrected) as a whole percent; null when nothing reviewed.
int? aiAccuracyPercent(int verified, int corrected) {
  final reviewed = verified + corrected;
  return reviewed == 0 ? null : (verified * 100 / reviewed).round();
}

/// The model chains the scan path produces (ImageAnalyzerManager).
enum AdminAiModelKind { mistral, mistralThenGpt, gptOnly, unknown, other }

AdminAiModelKind aiModelKind(String? chain) {
  if (chain == null || chain.isEmpty) return AdminAiModelKind.unknown;
  final parts = chain.split('>');
  final hasMistral = parts.any((p) => p.startsWith('mistral'));
  final hasGpt = parts.any((p) => p.startsWith('gpt'));
  if (hasMistral && hasGpt) return AdminAiModelKind.mistralThenGpt;
  if (hasMistral) return AdminAiModelKind.mistral;
  if (hasGpt) return AdminAiModelKind.gptOnly;
  return AdminAiModelKind.other;
}

/// Companies tab: search by name, optional profile filter.
List<AdminAiCompanyRow> filterAiCompanies(Iterable<AdminAiCompanyRow> rows, {String query = '', int? profileId}) {
  final q = query.trim().toLowerCase();
  return rows
      .where((r) => profileId == null || r.aiProfileId == profileId)
      .where((r) => q.isEmpty || r.companyName.toLowerCase().contains(q))
      .toList();
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Usage filters - all optional.
class AdminAiUsageFilters {
  const AdminAiUsageFilters({this.companyId, this.profileId, this.from, this.to});

  static const none = AdminAiUsageFilters();

  final String? companyId;
  final int? profileId;
  final DateTime? from;
  final DateTime? to;

  bool get isEmpty => companyId == null && profileId == null && from == null && to == null;

  AdminAiUsageFilters withCompany(String? id) =>
      AdminAiUsageFilters(companyId: id, profileId: profileId, from: from, to: to);
  AdminAiUsageFilters withProfile(int? id) =>
      AdminAiUsageFilters(companyId: companyId, profileId: id, from: from, to: to);
  AdminAiUsageFilters withDates(DateTime? f, DateTime? t) =>
      AdminAiUsageFilters(companyId: companyId, profileId: profileId, from: f, to: t);

  Map<String, String> toQuery() => {
    'companyId': ?companyId,
    if (profileId != null) 'profileId': '$profileId',
    if (from != null) 'from': _ymd(from!),
    if (to != null) 'to': _ymd(to!),
  };

  @override
  bool operator ==(Object other) =>
      other is AdminAiUsageFilters &&
      other.companyId == companyId &&
      other.profileId == profileId &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(companyId, profileId, from, to);
}

/// Save to expense - the values the expense should have.
class AdminAiCorrection {
  const AdminAiCorrection({this.merchant, this.date, this.amount, this.currency, this.receiptNumber});

  final String? merchant;
  final String? date;
  final double? amount;
  final String? currency;
  final String? receiptNumber;

  Map<String, dynamic> toJson() => {
    'merchant': merchant,
    'date': date,
    'amount': amount,
    'currency': currency,
    'receiptNumber': receiptNumber,
  };
}

/// The profile with [id], or null.
AdminAiProfileRow? aiProfileById(Iterable<AdminAiProfileRow> rows, int? id) =>
    id == null ? null : rows.where((r) => r.aiProfileId == id).firstOrNull;

/// The default profile's number (else the first one's) - what a new profile copies.
int? defaultAiProfileId(Iterable<AdminAiProfileRow> rows) =>
    (rows.where((r) => r.isDefault).firstOrNull ?? rows.firstOrNull)?.aiProfileId;

/// The company with [companyId], or null.
AdminAiCompanyRow? aiCompanyById(Iterable<AdminAiCompanyRow> rows, String companyId) =>
    rows.where((c) => c.companyId == companyId).firstOrNull;

/// Every shown company is selected (and there is at least one).
bool allAiCompaniesSelected(Iterable<AdminAiCompanyRow> shown, Set<String> selected) =>
    shown.isNotEmpty && shown.every((c) => selected.contains(c.companyId));

/// [selected] with [companyIds] added ([on]) or removed.
Set<String> toggleAiCompanies(Set<String> selected, Iterable<String> companyIds, {required bool on}) =>
    on ? {...selected, ...companyIds} : selected.difference(companyIds.toSet());

/// Accuracy bar tier: null nothing reviewed, else good (85+), fair (70+), poor.
enum AdminAiAccuracyTier { good, fair, poor }

AdminAiAccuracyTier? aiAccuracyTier(int? percent) => percent == null
    ? null
    : percent >= 85
    ? AdminAiAccuracyTier.good
    : percent >= 70
    ? AdminAiAccuracyTier.fair
    : AdminAiAccuracyTier.poor;

/// The first scan of the list nobody reviewed yet.
AdminAiScanRow? firstUnreviewedAiScan(Iterable<AdminAiScanRow> rows) =>
    rows.where((r) => r.aiReviewStatusId == null).firstOrNull;

/// The first [max] of [items] and how many more there are - a confirm lists a
/// few names, not every one of 40 selected companies.
({List<T> shown, int more}) aiFirstItems<T>(List<T> items, {int max = 5}) =>
    (shown: items.take(max).toList(), more: items.length > max ? items.length - max : 0);

/// The default profile's number, or null when none is marked.
int? markedDefaultAiProfileId(Iterable<AdminAiProfileRow> rows) =>
    rows.where((r) => r.isDefault).firstOrNull?.aiProfileId;

/// A version mark, "v3". Like , the  is a universal mark - not translated.
String adminAiVersion(int? n) => n == null ? '—' : 'v$n';

/// A receipt image link the admin may open: https only.
bool isSafeAdminAiLink(String? url) => url != null && Uri.tryParse(url)?.scheme == 'https';

/// "1 company" / "3 companies" - [one] and [many] are the localized nouns.
String adminAiCount(int n, String one, String many) => '$n ${n == 1 ? one : many}';

/// Wraps [s] as a left-to-right isolate, so "#1 Standard · v1" keeps its order
/// inside Hebrew text, pills and dropdown entries.
String adminAiLtr(String s) => '\u2066$s\u2069';

/// A previous version (status 3) can be restored as the draft; the draft and
/// the published version cannot.
bool aiVersionRestorable(int statusId) => statusId == 3;
