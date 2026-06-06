import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_list_item.dart';
import '../../providers/manager_dashboard_provider.dart';
import '../../theme/app_theme.dart';
import 'sheet_bucket_enums.dart';
import 'sheet_bucket_card.dart';

/// Approved card — terminal sheets (`statusId == 3`). Audit / history view.
///
/// Default collapsed (story 02 §2.7). No header amount — historical sum
/// isn't actionable. First call site that renders the 4-state badge's
/// success-tone variant (visible only in row internals if/when we add a
/// row-level status badge; the card itself doesn't show one).
class ApprovedCard extends ConsumerWidget {
  const ApprovedCard({
    super.key,
    required this.onRowTap,
    this.initiallyExpanded = false,
    this.highlighted = false,
  });

  final void Function(ExpenseSheetListItem) onRowTap;

  /// Initial expand state — overridable so the dashboard's Approved counter can
  /// open this bucket (the "Processed" section) on arrival (§8).
  final bool initiallyExpanded;

  /// Draw the focus ring — set when reached via the Approved counter (§8).
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(selectedEmployeeFilterProvider);
    final dataAsync = ref.watch(approvedSheetsProvider(filter));

    return SheetBucketCard(
      title: l10n.approvedCardTitle,
      dataAsync: dataAsync,
      timestampSource: SheetBucketTimestampSource.reviewedAt,
      timestampLabel: l10n.approvedAt,
      actionStyle: SheetBucketActionStyle.eyeIcon,
      emptyTitle: l10n.noApprovedSheets,
      // No icon — audit empty state is text-only per story 02 §2.7.
      initiallyExpanded: initiallyExpanded,
      highlightColor: highlighted ? AppTheme.primary : null,
      onRowTap: onRowTap,
      // No header trailing — historical totals not surfaced here.
    );
  }
}
