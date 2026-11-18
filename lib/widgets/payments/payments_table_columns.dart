/// Fixed column widths shared by the desktop Payments table header, rows and
/// total row. One source of truth so the cells always line up.
/// Order (owner, 2026-11-18): employee + status pill, amount, action, sheet
/// type, cycle, approved date, processed date, gov ID.
class PaymentsTableColumns {
  static const double checkbox = 44;
  static const double employee = 220;
  static const double amount = 110;

  /// "Process" (pending) / "Edit" (processed) button, with its icon.
  static const double action = 120;
  static const double sheetType = 150;
  static const double cycle = 120;
  static const double approvedDate = 105;
  static const double processedDate = 105;
  static const double govId = 100;

  /// Horizontal padding around each cell.
  static const double cellGap = 8;

  /// The Sheet type column shows only when more than one type is paid.
  static double tableWidth({required bool showSheetType}) =>
      showSheetType ? minTableWidth : minTableWidth - sheetType - cellGap;

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
