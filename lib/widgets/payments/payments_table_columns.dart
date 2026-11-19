/// Fixed column widths shared by the desktop Payments table header, rows and
/// total row. One source of truth so the cells always line up.
/// Order (owner, 2026-11-18; PC-9 menu): select, employee + status pill,
/// amount, actions (⋮), sheet type, cycle, approved date, processed date,
/// gov ID.
class PaymentsTableColumns {
  /// Select checkbox. The eye left for the row menu (PC-9).
  static const double selectBox = 44;
  static const double checkbox = selectBox;
  static const double employee = 220;
  static const double amount = 110;

  /// The row's vertical ⋮ menu (View, Settle or Edit) - PC-9, D35.
  static const double action = 76;

  /// "Settle" / "Edit" button on a phone row, with its icon.
  static const double actionButton = 120;
  static const double sheetType = 150;
  static const double cycle = 120;
  static const double approvedDate = 105;
  static const double processedDate = 105;
  static const double govId = 100;

  /// Horizontal padding around each cell.
  static const double cellGap = 8;

  /// The Sheet type column shows only when more than one type is paid; an
  /// employee's History has no gov ID column.
  static double tableWidth({required bool showSheetType, bool showGovId = true}) =>
      minTableWidth -
      (showSheetType ? 0 : sheetType + cellGap) -
      (showGovId ? 0 : govId + cellGap);

  static const double minTableWidth =
      checkbox +
      employee +
      amount +
      action +
      sheetType +
      cycle +
      approvedDate +
      processedDate +
      govId +
      cellGap * 9;
}
