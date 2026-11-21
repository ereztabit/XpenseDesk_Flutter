import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_scan_review.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_review_utils.dart';
import 'ai_scan_correct_input.dart';

/// One field of the scan review on a phone (below 600px), stacked instead of a
/// table row: the field name, then Mistral / GPT / AI result / On the expense
/// as label-value lines, then the Correct value input full width.
class AiScanFieldBlock extends StatelessWidget {
  const AiScanFieldBlock({
    super.key,
    required this.review,
    required this.field,
    required this.caption,
    required this.value,
    required this.locked,
    required this.changed,
    required this.onChanged,
    this.formRev = 0,
  });

  final AdminAiScanReview review;
  final AdminAiField field;
  final String caption;

  /// The Correct-value input; null = no input (VAT is shown, never saved).
  final String? value;
  final bool locked;
  final bool changed;
  final ValueChanged<String> onChanged;
  final int formRev;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final read = aiFieldReadout(review, field);
    const cell = TextStyle(fontSize: 13, color: AppTheme.foreground);
    const label = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.mutedForeground);
    final amber = cell.copyWith(color: AppTheme.amber, fontWeight: FontWeight.w600);

    Widget line(String caption, String? v, {TextStyle? style, String? empty, String? note}) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(caption, style: label)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v ?? empty ?? '—',
                  style: v == null ? cell.copyWith(color: AppTheme.mutedForeground) : (style ?? cell),
                ),
                if (note != null) Text(note, style: const TextStyle(fontSize: 11, color: AppTheme.amber)),
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border, width: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(caption, style: cell.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          line(l10n.adminAiColMistral, read.mistral, style: read.disagree ? amber : null),
          line(
            l10n.adminAiColGpt,
            read.gpt,
            style: read.disagree ? amber : null,
            empty: review.gpt == null ? l10n.adminAiNotCalled : null,
          ),
          line(l10n.adminAiColAiResult, read.ai, style: cell.copyWith(fontWeight: FontWeight.w600)),
          line(
            l10n.adminAiColOnExpense,
            read.onExpense,
            style: read.employeeChanged ? amber : null,
            note: read.employeeChanged ? l10n.adminAiChangedByEmployee : null,
          ),
          if (value != null) ...[
            const SizedBox(height: 6),
            Text(l10n.adminAiColCorrect, style: label),
            const SizedBox(height: 4),
            AiScanCorrectInput(
              field: field,
              value: value!,
              locked: locked,
              changed: changed,
              onChanged: onChanged,
              formRev: formRev,
            ),
          ],
        ],
      ),
    );
  }
}
