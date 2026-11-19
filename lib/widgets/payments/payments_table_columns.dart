/// Fixed column widths shared by the desktop Payments table header, rows and
/// total row. One source of truth so the cells always line up.
/// Order (owner QA 2026-11-19): select box or Edit + eye, employee, amount,
/// payment status, sheet type, cycle, approved date, closed date, gov ID.
class PaymentsTableColumns {
  /// Select box (or Edit) slot, then the 32px eye.
  static const double selectSlot = 40;
  static const double checkbox = selectSlot + 36;
  static const double employee = 200;
  static const double amount = 110;

  /// Plain-text payment status (no pill).
  static const double status = 120;
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
      status +
      sheetType +
      cycle +
      approvedDate +
      processedDate +
      govId +
      cellGap * 9;
}
