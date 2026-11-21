import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_scan_review.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_review_utils.dart';
import 'ai_scan_correct_input.dart';

/// One field of the scan review: Mistral / GPT / AI result / on the expense /
/// the correct value. Amber where the two models disagree. 600px and up; a
/// phone gets [AiScanFieldBlock] instead.
class AiScanFieldRow extends StatelessWidget {
  const AiScanFieldRow({
    super.key,
    required this.review,
    required this.field,
    required this.caption,
    required this.value,
    required this.locked,
    required this.changed,
    required this.onChanged,
    required this.correctWidth,
    this.formRev = 0,
  });

  /// Field, Mistral, GPT, AI result, On the expense. The Correct value column
  /// takes the rest of the card ([correctWidth], at least [minCorrectWidth]).
  static const List<double> fixedWidths = [90, 100, 100, 100, 110];
  static const double minCorrectWidth = 220;
  static double get minTableWidth => fixedWidths.fold<double>(0, (a, b) => a + b) + minCorrectWidth;

  final double correctWidth;

  /// The form baseline revision - a new one re-creates the input with its value.
  final int formRev;

  final AdminAiScanReview review;
  final AdminAiField field;
  final String caption;

  /// The Correct-value input; null = no input (VAT is shown, never saved).
  final String? value;
  final bool locked;
  final bool changed;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final read = aiFieldReadout(review, field);
    const cell = TextStyle(fontSize: 13, color: AppTheme.foreground);
    const muted = TextStyle(fontSize: 13, color: AppTheme.mutedForeground);
    final amber = cell.copyWith(color: AppTheme.amber, fontWeight: FontWeight.w600);
    final disagreeBg = read.disagree ? AppTheme.amber.withAlpha(25) : null;

    Widget box(int i, Widget child, {Color? bg}) => Container(
      width: i < fixedWidths.length ? fixedWidths[i] : correctWidth,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: child,
    );

    Widget model(String? v, {bool notCalled = false}) =>
        Text(v ?? (notCalled ? l10n.adminAiNotCalled : '—'), style: v == null ? muted : (read.disagree ? amber : cell));

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border, width: .5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          box(0, Text(caption, style: cell.copyWith(fontWeight: FontWeight.w600))),
          box(1, model(read.mistral), bg: disagreeBg),
          box(2, model(read.gpt, notCalled: review.gpt == null), bg: disagreeBg),
          box(3, Text(read.ai ?? '—', style: cell.copyWith(fontWeight: FontWeight.w600))),
          box(
            4,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(read.onExpense ?? '—', style: read.employeeChanged ? amber : cell),
                if (read.employeeChanged)
                  Text(l10n.adminAiChangedByEmployee, style: const TextStyle(fontSize: 11, color: AppTheme.amber)),
              ],
            ),
          ),
          box(
            5,
            value == null
                ? const SizedBox.shrink()
                : AiScanCorrectInput(
                    field: field,
                    value: value!,
                    locked: locked,
                    changed: changed,
                    onChanged: onChanged,
                    formRev: formRev,
                  ),
          ),
        ],
      ),
    );
  }
}
