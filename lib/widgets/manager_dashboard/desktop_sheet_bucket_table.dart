import 'package:flutter/material.dart';

import '../../models/expense_sheet_list_item.dart';
import '../selectable_scope.dart';
import 'desktop_sheet_bucket_header.dart';
import 'desktop_sheet_bucket_row.dart';
import 'sheet_bucket_enums.dart';

/// Desktop table body for one bucket card — composes
/// [DesktopSheetBucketHeader] + a sequence of [DesktopSheetBucketRow]s.
class DesktopSheetBucketTable extends StatelessWidget {
  const DesktopSheetBucketTable({
    super.key,
    required this.items,
    required this.companyLocale,
    required this.timestampSource,
    required this.timestampLabel,
    required this.actionStyle,
    required this.onRowTap,
  });

  final List<ExpenseSheetListItem> items;
  final String companyLocale;
  final SheetBucketTimestampSource timestampSource;
  final String timestampLabel;
  final SheetBucketActionStyle actionStyle;
  final void Function(ExpenseSheetListItem) onRowTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DesktopSheetBucketHeader(timestampLabel: timestampLabel),
        SelectableScope(
          child: Column(
            children: [
              ...items.map(
                (sheet) => DesktopSheetBucketRow(
                  sheet: sheet,
                  companyLocale: companyLocale,
                  timestampSource: timestampSource,
                  actionStyle: actionStyle,
                  onTap: () => onRowTap(sheet),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
