import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../admin/admin_search_field.dart';

/// B2 search row: [AdminSearchField] + the "Needs attention" toggle at its
/// end (amber outline; pressed = solid amber). The label hides below 640px;
/// the count pill (LTR) always shows.
class BudgetSearchRow extends StatelessWidget {
  const BudgetSearchRow({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.attentionOn,
    required this.attentionCount,
    required this.onAttentionToggle,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;
  final bool attentionOn;
  final int attentionCount;
  final VoidCallback onAttentionToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showLabel = context.screenWidth >= 640;
    final fg = attentionOn ? Colors.white : AppTheme.amber;

    return Row(
      children: [
        Expanded(
          child: AdminSearchField(
            value: query,
            hintText: l10n.budgetsSearchHint,
            clearTooltip: l10n.clear,
            onChanged: onQueryChanged,
          ),
        ),
        // Nothing to filter for: no toggle (user decision 2026-11-17). It
        // stays while on, so it can always be switched off.
        if (attentionOn || attentionCount > 0) ...[
        const SizedBox(width: 8),
        Semantics(
          button: true,
          toggled: attentionOn,
          label: l10n.budgetsAttentionToggle,
          child: Material(
            color: attentionOn ? AppTheme.amber : AppTheme.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              side: const BorderSide(color: AppTheme.amber),
            ),
            child: InkWell(
              onTap: onAttentionToggle,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: fg),
                      if (showLabel) ...[
                        const SizedBox(width: 6),
                        Text(
                          l10n.budgetsAttentionToggle,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: attentionOn ? Colors.white.withAlpha(51) : AppTheme.amber.withAlpha(38),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$attentionCount',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        ],
      ],
    );
  }
}
