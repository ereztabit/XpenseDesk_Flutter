import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/conversion_preview.dart';
import '../services/expense_service.dart';

enum ConversionStatus { idle, loading, success, error }

/// Per-form controller that turns amount/currency/date edits into a live
/// "≈ base currency" preview via [ExpenseService.convertToBase].
///
/// Owned by the screen (created in initState, disposed in dispose). Debounces
/// amount keystrokes; the debounce window counts as [ConversionStatus.loading]
/// so the save button stays gated until the value settles. Currency/date
/// changes evaluate immediately.
class ConversionPreviewController extends ChangeNotifier {
  ConversionPreviewController(this._service);

  final ExpenseService _service;

  static const _debounceDelay = Duration(milliseconds: 450);

  Timer? _debounce;

  /// Monotonic guard so a slow in-flight request can't overwrite a newer one.
  int _seq = 0;

  /// Inputs the last [evaluate] acted on. Guards against no-op re-evaluations
  /// — e.g. the amount field's controller notifies on focus/selection changes,
  /// not just text edits, so we must ignore calls where nothing actually
  /// changed (otherwise focusing the field would re-trigger a conversion).
  String? _lastKey;

  ConversionStatus status = ConversionStatus.idle;
  ConversionPreview? preview;
  Object? error;

  /// Save is allowed only when there's no conversion pending and no error —
  /// i.e. idle (nothing to convert / base currency) or a settled success.
  bool get canSave =>
      status == ConversionStatus.idle || status == ConversionStatus.success;

  /// Re-evaluate the preview. Call on every amount / currency / date change.
  /// No conversion happens (and save is not gated) when the amount is empty,
  /// the currency is the base currency, or required inputs are missing.
  void evaluate({
    required String? currency,
    required num? amount,
    required DateTime? date,
    required String baseCurrency,
  }) {
    // Ignore calls where no input actually changed (e.g. field focus).
    final key = '${currency ?? ''}|${amount ?? ''}|'
        '${date?.toIso8601String() ?? ''}|$baseCurrency';
    if (key == _lastKey) return;
    _lastKey = key;

    _debounce?.cancel();

    final isBase = currency != null &&
        currency.toUpperCase() == baseCurrency.toUpperCase();
    if (amount == null ||
        amount <= 0 ||
        currency == null ||
        currency.isEmpty ||
        date == null ||
        isBase) {
      _seq++;
      _set(ConversionStatus.idle, preview: null, error: null);
      return;
    }

    // Enter loading right away so the debounce window also gates save.
    _set(ConversionStatus.loading, preview: null, error: null);

    final mySeq = ++_seq;
    _debounce = Timer(_debounceDelay, () async {
      try {
        final result = await _service.convertToBase(
          currency: currency,
          amount: amount,
          date: date,
        );
        if (mySeq != _seq) return;
        _set(ConversionStatus.success, preview: result, error: null);
      } catch (e) {
        if (mySeq != _seq) return;
        _set(ConversionStatus.error, preview: null, error: e);
      }
    });
  }

  void _set(ConversionStatus next,
      {required ConversionPreview? preview, required Object? error}) {
    status = next;
    this.preview = preview;
    this.error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
