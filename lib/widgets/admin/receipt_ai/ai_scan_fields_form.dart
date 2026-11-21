import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_scan_review.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_review_utils.dart';
import '../../../utils/admin_ai_utils.dart';
import '../../app_button.dart';
import '../../profile/profile_section_card.dart';
import 'ai_button_row.dart';
import 'ai_scan_field_block.dart';
import 'ai_scan_field_row.dart';

/// What the AI read vs what the expense holds, with a Correct-value input per
/// field, and the Save to expense / Verified buttons. Holds the form only; the
/// calls are the caller's (`AiScanFieldsCard`), so it has no service imports
/// and runs in VM widget tests. A closed expense keeps its amount and currency
/// (and its date when foreign) - [aiLockedFields].
///
/// A row-per-field layout, not `AdminFixedTable`: its rows are stateless cells
/// inside a selection area and cannot hold text inputs.
class AiScanFieldsForm extends StatefulWidget {
  const AiScanFieldsForm({
    super.key,
    required this.review,
    required this.busy,
    required this.onSave,
    required this.onVerify,
  });

  final AdminAiScanReview review;
  final bool busy;
  final ValueChanged<AdminAiCorrection> onSave;
  final VoidCallback onVerify;

  @override
  State<AiScanFieldsForm> createState() => _AiScanFieldsFormState();
}

class _AiScanFieldsFormState extends State<AiScanFieldsForm> {
  late AdminAiReviewForm _form = AdminAiReviewForm(widget.review.expense);

  /// Bumped with every new baseline, so the inputs re-read their values.
  int _formRev = 0;

  /// The review reloads after a save or Verified (when the scan stays open):
  /// the reloaded expense becomes the new baseline - nothing highlighted,
  /// Save disabled, Verified enabled.
  @override
  void didUpdateWidget(AiScanFieldsForm old) {
    super.didUpdateWidget(old);
    if (!identical(old.review, widget.review)) {
      _form = AdminAiReviewForm(widget.review.expense);
      _formRev++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final r = widget.review;
    final changedCount = _form.changed.length;
    final locked = aiLockedFields(isClosed: r.isClosed, isForeign: r.isForeign);
    const head = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.mutedForeground);

    String caption(AdminAiField f) => switch (f) {
      AdminAiField.merchant => l10n.adminAiFieldMerchant,
      AdminAiField.date => l10n.adminAiFieldDate,
      AdminAiField.amount => l10n.adminAiFieldAmount,
      AdminAiField.currency => l10n.adminAiFieldCurrency,
      AdminAiField.vat => l10n.adminAiFieldVat,
      AdminAiField.receiptNumber => l10n.adminAiFieldReceiptNo,
    };

    return ProfileSectionCard(
      icon: Icons.fact_check_outlined,
      title: l10n.adminAiReadTitle,
      children: [
        Text(l10n.adminAiReadIntro, style: const TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
        const SizedBox(height: 12),
        // Fills the card; the Correct value column takes the room left. Below
        // 600px each field is a stacked block, its input full width.
        LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth < 600) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final f in AdminAiField.values)
                    AiScanFieldBlock(
                      review: r,
                      field: f,
                      caption: caption(f),
                      value: f == AdminAiField.vat ? null : _form.values[f],
                      locked: locked.contains(f),
                      changed: f != AdminAiField.vat && _form.isChanged(f),
                      onChanged: (v) => setState(() => _form.values[f] = v),
                      formRev: _formRev,
                    ),
                ],
              );
            }
            final width = c.maxWidth > AiScanFieldRow.minTableWidth ? c.maxWidth : AiScanFieldRow.minTableWidth;
            final correctWidth = width - AiScanFieldRow.minTableWidth + AiScanFieldRow.minCorrectWidth;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final (label, w) in [
                          (l10n.adminAiColField, AiScanFieldRow.fixedWidths[0]),
                          (l10n.adminAiColMistral, AiScanFieldRow.fixedWidths[1]),
                          (l10n.adminAiColGpt, AiScanFieldRow.fixedWidths[2]),
                          (l10n.adminAiColAiResult, AiScanFieldRow.fixedWidths[3]),
                          (l10n.adminAiColOnExpense, AiScanFieldRow.fixedWidths[4]),
                          (l10n.adminAiColCorrect, correctWidth),
                        ])
                          SizedBox(
                            width: w,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(label, style: head),
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 1, color: AppTheme.border),
                    for (final f in AdminAiField.values)
                      AiScanFieldRow(
                        review: r,
                        field: f,
                        caption: caption(f),
                        value: f == AdminAiField.vat ? null : _form.values[f],
                        locked: locked.contains(f),
                        changed: f != AdminAiField.vat && _form.isChanged(f),
                        onChanged: (v) => setState(() => _form.values[f] = v),
                        correctWidth: correctWidth,
                        formRev: _formRev,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        if (r.isClosed)
          Text(
            r.isForeign ? l10n.adminAiClosedForeignNote : l10n.adminAiClosedNote,
            style: const TextStyle(fontSize: 13, color: AppTheme.amber, fontWeight: FontWeight.w600),
          ),
        Text(l10n.adminAiReviewNote, style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
        const SizedBox(height: 12),
        // Side by side at the card's start edge, under the table.
        AiButtonRow(
          children: [
            AppButton(
              label: changedCount > 0 ? '${l10n.adminAiSaveToExpense} ($changedCount)' : l10n.adminAiSaveToExpense,
              icon: Icons.save_outlined,
              isLoading: widget.busy,
              onPressed: widget.busy || !_form.canSave(isClosed: r.isClosed, isForeign: r.isForeign)
                  ? null
                  : () => widget.onSave(_form.toCorrection()),
            ),
            AppButton(
              label: l10n.adminAiVerifiedButton,
              variant: AppButtonVariant.success,
              icon: Icons.check,
              onPressed: widget.busy || !_form.canVerify ? null : widget.onVerify,
            ),
          ],
        ),
      ],
    );
  }
}
