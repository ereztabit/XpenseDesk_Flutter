/// Fixed column widths shared by the desktop Payments table header and rows.
/// One source of truth so header and body cells always line up.
class PaymentsTableColumns {
  static const double checkbox = 44;
  static const double employee = 140;
  static const double govId = 100;
  static const double email = 180;
  static const double cycle = 110;
  static const double approvedDate = 105;
  static const double amount = 86;
  static const double paymentStatus = 130;
  static const double processedDate = 105;

  /// Small "Edit" text button (#13) on every row.
  static const double action = 96;

  /// Horizontal padding around each cell.
  static const double cellGap = 8;

  static const double minTableWidth = checkbox +
      employee +
      govId +
      email +
      cycle +
      approvedDate +
      amount +
      paymentStatus +
      processedDate +
      action +
      cellGap * 10;
}
