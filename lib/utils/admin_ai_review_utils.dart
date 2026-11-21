import '../models/admin_ai_profile.dart';
import '../models/admin_ai_scan_review.dart';
import 'admin_ai_utils.dart';

/// FS-1026 Receipt AI - the editor and review rules (no widgets here).

/// The reviewable fields, in table order. VAT is shown but never saved.
enum AdminAiField { merchant, date, amount, currency, vat, receiptNumber }

String? aiFieldValue(AdminAiScanValues? v, AdminAiField f) {
  if (v == null) return null;
  return switch (f) {
    AdminAiField.merchant => v.merchant,
    AdminAiField.date => v.date,
    AdminAiField.amount => _num(v.amount),
    AdminAiField.currency => v.currency,
    AdminAiField.vat => _num(v.taxAmount),
    AdminAiField.receiptNumber => v.receiptNumber,
  };
}

String? _num(double? n) => n?.toStringAsFixed(2);

String _norm(String? s) => (s ?? '').trim();

/// The two models read the field differently (both read something).
bool aiModelsDisagree(AdminAiScanReview r, AdminAiField f) {
  final m = aiFieldValue(r.mistral?.values, f);
  final g = aiFieldValue(r.gpt?.values, f);
  if (m == null || g == null) return false;
  return f == AdminAiField.amount || f == AdminAiField.vat
      ? double.tryParse(m) != double.tryParse(g)
      : _norm(m) != _norm(g);
}

/// One field as the review shows it: each model's reading, the AI result and
/// the expense value; [employeeChanged] = the expense no longer holds the AI
/// result (VAT is never saved, so never "changed").
({String? mistral, String? gpt, String? ai, String? onExpense, bool disagree, bool employeeChanged}) aiFieldReadout(
  AdminAiScanReview r,
  AdminAiField f,
) {
  final ai = aiFieldValue(r.aiResult, f);
  final onExpense = aiFieldValue(r.expense, f);
  return (
    mistral: aiFieldValue(r.mistral?.values, f),
    gpt: aiFieldValue(r.gpt?.values, f),
    ai: ai,
    onExpense: onExpense,
    disagree: aiModelsDisagree(r, f),
    employeeChanged: f != AdminAiField.vat && ai != null && onExpense != ai,
  );
}

/// The values in the Correct-value inputs against what the expense holds.
class AdminAiReviewForm {
  AdminAiReviewForm(this.expense) : values = {for (final f in editable) f: aiFieldValue(expense, f) ?? ''};

  static const editable = [
    AdminAiField.merchant,
    AdminAiField.date,
    AdminAiField.amount,
    AdminAiField.currency,
    AdminAiField.receiptNumber,
  ];

  final AdminAiScanValues expense;
  final Map<AdminAiField, String> values;

  bool isChanged(AdminAiField f) {
    final now = _norm(values[f]);
    final was = _norm(aiFieldValue(expense, f));
    if (f == AdminAiField.amount) return double.tryParse(now) != double.tryParse(was);
    if (f == AdminAiField.currency) return now.toUpperCase() != was.toUpperCase();
    return now != was;
  }

  List<AdminAiField> get changed => editable.where(isChanged).toList();

  bool get moneyChanged => isChanged(AdminAiField.amount) || isChanged(AdminAiField.currency);

  /// Save to expense: something differs, and nothing locked
  /// ([aiLockedFields]) is among the changes.
  bool canSave({required bool isClosed, bool isForeign = false}) {
    final locked = aiLockedFields(isClosed: isClosed, isForeign: isForeign);
    return changed.isNotEmpty && !changed.any(locked.contains);
  }

  /// Verified means "the expense is right as it is" - not while editing.
  bool get canVerify => changed.isEmpty;

  AdminAiCorrection toCorrection() {
    String? v(AdminAiField f) => _norm(values[f]).isEmpty ? null : _norm(values[f]);
    return AdminAiCorrection(
      merchant: v(AdminAiField.merchant),
      date: v(AdminAiField.date),
      amount: double.tryParse(v(AdminAiField.amount) ?? ''),
      currency: v(AdminAiField.currency)?.toUpperCase(),
      receiptNumber: v(AdminAiField.receiptNumber),
    );
  }
}

/// The next expense in [ids] after [current] that is not in [reviewed]; wraps
/// around; null when every other one is reviewed.
String? nextUnreviewedId(List<String> ids, String current, Set<String> reviewed) {
  if (ids.isEmpty) return null;
  final start = ids.indexOf(current);
  for (var step = 1; step <= ids.length; step++) {
    final id = ids[(start + step) % ids.length];
    if (id != current && !reviewed.contains(id)) return id;
  }
  return null;
}

/// The one before [current] in [ids]; null at the start or when not listed.
String? previousId(List<String> ids, String current) {
  final i = ids.indexOf(current);
  return i > 0 ? ids[i - 1] : null;
}

/// The profile editor's unsaved state: the text in the editors against the
/// version they were loaded from.
class AdminAiDraftEdit {
  AdminAiDraftEdit({required this.system, required this.user, required Map<String, String> fields})
    : fields = Map.of(fields),
      _base = (system, user, Map.of(fields));

  String system;
  String user;
  final Map<String, String> fields;
  final (String, String, Map<String, String>) _base;

  bool get isDirty => system != _base.$1 || user != _base.$2 || fields.entries.any((e) => _base.$3[e.key] != e.value);

  /// Fields whose instruction differs from [published].
  static Set<String> fieldsChangedFrom(Map<String, String> current, Map<String, String>? published) =>
      published == null ? const {} : current.keys.where((k) => published[k] != current[k]).toSet();
}

/// Fields Save to expense may not change. A closed expense keeps its money;
/// a closed foreign-currency one keeps its date too (the rate is tied to it).
Set<AdminAiField> aiLockedFields({required bool isClosed, required bool isForeign}) => {
  if (isClosed) ...{AdminAiField.amount, AdminAiField.currency},
  if (isClosed && isForeign) AdminAiField.date,
};

/// What the draft changes against the published version: GPT text, and which
/// Mistral fields.
({bool gptChanged, Set<String> fields}) aiDraftChanges(AdminAiProfileDetail detail) {
  final draft = detail.draft;
  final published = detail.published;
  if (draft == null) return (gptChanged: false, fields: const {});
  return (
    gptChanged: draft.gptSystemPrompt != published?.gptSystemPrompt || draft.gptUserPrompt != published?.gptUserPrompt,
    fields: AdminAiDraftEdit.fieldsChangedFrom(draft.fieldMap, published?.fieldMap),
  );
}

/// How many scans of [queue] are still unreviewed.
int aiUnreviewedCount(List<String> queue, Set<String> reviewed) => queue.where((id) => !reviewed.contains(id)).length;

/// The page render of a PDF upload (the scan record's convert-to-image step),
/// or null - what the original-image preview shows for a PDF.
String? aiConvertedImageUrl(Map<String, dynamic>? scanRecord) {
  final steps = scanRecord?['steps'];
  if (steps is! List) return null;
  for (final step in steps.whereType<Map<String, dynamic>>()) {
    final output = step['output'];
    if (step['step'] == 'convert-to-image' && output is Map<String, dynamic> && output['url'] is String) {
      return output['url'] as String;
    }
  }
  return null;
}

/// The file name a download saves under: the URL's last path segment.
String aiFileNameFromUrl(String url, String fallback) {
  final segments = Uri.tryParse(url)?.pathSegments ?? const [];
  return segments.isEmpty || segments.last.isEmpty ? fallback : segments.last;
}
