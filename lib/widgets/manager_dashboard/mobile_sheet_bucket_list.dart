import 'package:flutter/material.dart';

import '../../models/expense_sheet_list_item.dart';
import 'mobile_sheet_bucket_row.dart';
import 'sheet_bucket_enums.dart';

/// Mobile list body for one bucket card — composes a sequence of
/// [MobileSheetBucketRow]s.
class MobileSheetBucketList extends StatelessWidget {
  const MobileSheetBucketList({
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
      children: List.generate(items.length, (index) {
        return MobileSheetBucketRow(
          sheet: items[index],
          companyLocale: companyLocale,
          timestampSource: timestampSource,
          timestampLabel: timestampLabel,
          actionStyle: actionStyle,
          isLast: index == items.length - 1,
          onTap: () => onRowTap(items[index]),
        );
      }),
    );
  }
}
