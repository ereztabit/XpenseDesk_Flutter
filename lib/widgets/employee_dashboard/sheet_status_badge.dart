import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_status.dart';
import '../../theme/app_theme.dart';

/// Small rounded pill rendering one of the four server sheet statuses.
///
/// The widget supports all four states so it can be reused by the manager
/// dashboard. The employee dashboard never feeds it `Approved` since
/// finalised sheets live in history (story 01 §2.3).
class SheetStatusBadge extends StatelessWidget {
  const SheetStatusBadge({super.key, required this.statusId});

  final int statusId;

  Color _background() {
    final status = ExpenseSheetStatus.fromId(statusId);
    switch (status) {
      case ExpenseSheetStatus.draft:
        return AppTheme.muted;
      case ExpenseSheetStatus.waitingForApproval:
        return AppTheme.amber;
      case ExpenseSheetStatus.approved:
        return AppTheme.success;
      case ExpenseSheetStatus.declined:
        return AppTheme.destructive;
      case null:
        return AppTheme.muted;
    }
  }

  Color _foreground() {
    final status = ExpenseSheetStatus.fromId(statusId);
    if (status == ExpenseSheetStatus.draft) {
      return AppTheme.mutedForeground;
    }
    return Colors.white;
  }

  String _label(AppLocalizations l10n) {
    final status = ExpenseSheetStatus.fromId(statusId);
    switch (status) {
      case ExpenseSheetStatus.draft:
        return l10n.sheetStatusDraft;
      case ExpenseSheetStatus.waitingForApproval:
        return l10n.sheetStatusAwaiting;
      case ExpenseSheetStatus.approved:
        return l10n.sheetStatusApproved;
      case ExpenseSheetStatus.declined:
        return l10n.sheetStatusReturned;
      case null:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: _background(),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(l10n),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _foreground(),
        ),
      ),
    );
  }
}
