import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/expense_sheet_list_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/sheet_utils.dart';
import 'sheet_picker_tile.dart';

/// Card-styled dropdown that shows the active sheet on the trigger and lets
/// the employee switch between all their non-finalised sheets.
///
/// Order: current-cycle Draft first, then everything else by cycle id desc.
/// Selection writes to [selectedSheetIdProvider].
class SheetPickerDropdown extends ConsumerStatefulWidget {
  const SheetPickerDropdown({
    super.key,
    required this.sheets,
    required this.selectedSheet,
  });

  /// Non-finalised sheets to render — orchestrator filters out Approved.
  final List<ExpenseSheetListItem> sheets;

  /// Currently-selected sheet (header tile).
  final ExpenseSheetListItem selectedSheet;

  @override
  ConsumerState<SheetPickerDropdown> createState() =>
      _SheetPickerDropdownState();
}

class _SheetPickerDropdownState extends ConsumerState<SheetPickerDropdown> {
  final MenuController _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    final companyLocale = ref.watch(companyLocaleProvider);
    final sheets = SheetSelection.pickerOrder(widget.sheets);
    final selectedId = widget.selectedSheet.expenseSheetId;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return MenuAnchor(
          controller: _controller,
          crossAxisUnconstrained: false,
          style: MenuStyle(
            backgroundColor: const WidgetStatePropertyAll(AppTheme.card),
            elevation: const WidgetStatePropertyAll(4),
            minimumSize: WidgetStatePropertyAll(Size(width, 0)),
            maximumSize: WidgetStatePropertyAll(Size(width, double.infinity)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: 4),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          alignmentOffset: const Offset(0, 4),
          builder: (context, controller, _) => SheetPickerTile(
            sheet: widget.selectedSheet,
            companyLocale: companyLocale,
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
          menuChildren: [
            for (final sheet in sheets)
              SizedBox(
                width: width,
                child: SheetPickerTile(
                  sheet: sheet,
                  companyLocale: companyLocale,
                  isInsideMenu: true,
                  isSelected: sheet.expenseSheetId == selectedId,
                  onTap: () {
                    ref
                        .read(selectedSheetIdProvider.notifier)
                        .set(sheet.expenseSheetId);
                    _controller.close();
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
