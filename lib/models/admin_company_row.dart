/// How a company reads in the admin table once `isActive` and `paymentStatus`
/// are taken together. [unknown] carries a status string the client does not
/// recognise — it is displayed verbatim rather than guessed at.
enum AdminCompanyDisplayStatus {
  deactivated,
  pendingPayment,
  active,
  inactive,
  unknown,
}

/// One row of the platform-admin companies overview
/// (`GET /api/admin/companies`).
///
/// See docs/api-guides/platform-admin-api-guide.md §5. The platform company
/// itself is excluded server-side, so every row here is a real customer.
class AdminCompanyRow {
  final String companyId;
  final String companyName;
  final DateTime creationDate;

  /// Server-computed subscription state: `PendingPayment` | `Active` |
  /// `Inactive`. Never re-derive payment state on the client — display what the
  /// server returned. Read together with [isActive]: the server function only
  /// considers live companies, so a deactivated one falls through to
  /// `PendingPayment` and is indistinguishable from a never-paid signup.
  final String paymentStatus;

  /// Whether the company is live. When false, [paymentStatus] carries no
  /// meaning and the row must read as "Deactivated".
  final bool isActive;

  /// Company lifecycle status (e.g. `Active`). Not surfaced in the V1 table.
  final String companyStatus;

  final int userCount;
  final int expenseCount;

  const AdminCompanyRow({
    required this.companyId,
    required this.companyName,
    required this.creationDate,
    required this.paymentStatus,
    required this.isActive,
    required this.companyStatus,
    required this.userCount,
    required this.expenseCount,
  });

  /// The single state to show for this row.
  ///
  /// `paymentStatus` alone is not enough: the server function only considers
  /// live companies, so a deactivated one falls through to `PendingPayment` —
  /// identical on the wire to a brand-new signup that never paid. [isActive]
  /// tells them apart, and a deactivated company is surfaced as such rather
  /// than as merely unpaid.
  AdminCompanyDisplayStatus get displayStatus {
    if (!isActive) return AdminCompanyDisplayStatus.deactivated;
    switch (paymentStatus) {
      case 'PendingPayment':
        return AdminCompanyDisplayStatus.pendingPayment;
      case 'Active':
        return AdminCompanyDisplayStatus.active;
      case 'Inactive':
        return AdminCompanyDisplayStatus.inactive;
      default:
        return AdminCompanyDisplayStatus.unknown;
    }
  }

  factory AdminCompanyRow.fromJson(Map<String, dynamic> json) {
    return AdminCompanyRow(
      companyId: json['companyId'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      creationDate:
          DateTime.tryParse(json['creationDate'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      paymentStatus: json['paymentStatus'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      companyStatus: json['companyStatus'] as String? ?? '',
      userCount: (json['userCount'] as num?)?.toInt() ?? 0,
      expenseCount: (json['expenseCount'] as num?)?.toInt() ?? 0,
    );
  }
}
