/// The people list together with **which company it belongs to**.
///
/// The pairing is the point. The notifier holding this is `keepAlive` and holds
/// one company at a time, so a screen that simply read "the rows" could paint
/// the previously-opened company's staff under the new company's name until the
/// fetch lands — one customer's people on another customer's page.
///
/// Carrying the id in the state lets the screen check `companyId == the company
/// I am showing` and treat a mismatch as "still loading". That guard is on the
/// data, so it holds no matter when the load is scheduled.
class AdminCompanyUsers {
  final String companyId;
  final List<AdminCompanyUserRow> rows;

  const AdminCompanyUsers({required this.companyId, required this.rows});

  static const empty = AdminCompanyUsers(companyId: '', rows: []);
}

/// One person in a company, as the platform-admin impersonation picker sees them
/// (`GET /api/admin/companies/{companyId}/users`).
///
/// See docs/api-guides/impersonation-api-guide.md §2. The server already returns
/// managers before employees and each group by name, so an unfiltered render is
/// correct without sorting client-side.
class AdminCompanyUserRow {
  final String userId;

  /// Null until the person completes onboarding — they were invited but have
  /// never set a name. Render the email in that case; never an empty row.
  final String? fullName;

  final String email;

  /// 1 = Manager, 2 = Employee. Never 3: platform admins are filtered out
  /// server-side so an agent can never be offered another agent to connect as.
  final int roleId;

  /// Invitation lifecycle — `Pending` / `Active` / `Disabled`. Not the same
  /// thing as [isActive]: a `Pending` person has never signed in, a disabled one
  /// has and was switched off.
  final String status;

  /// Whether the account is enabled. Deactivated people are returned by the API
  /// on purpose and hidden by the client behind a checkbox, so this flag is what
  /// that checkbox filters on.
  final bool isActive;

  final DateTime createdAt;
  final DateTime? activationDate;

  const AdminCompanyUserRow({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.roleId,
    required this.status,
    required this.isActive,
    required this.createdAt,
    required this.activationDate,
  });

  static const int managerRoleId = 1;

  bool get isManager => roleId == managerRoleId;

  /// What to show in the name column. An invited person who never onboarded has
  /// no name, and an empty cell would read as a broken row rather than a pending
  /// invitation.
  String get displayName =>
      (fullName == null || fullName!.trim().isEmpty) ? email : fullName!;

  factory AdminCompanyUserRow.fromJson(Map<String, dynamic> json) {
    return AdminCompanyUserRow(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String?,
      email: json['email'] as String? ?? '',
      roleId: (json['roleId'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      activationDate:
          DateTime.tryParse(json['activationDate'] as String? ?? '')?.toUtc(),
    );
  }
}
