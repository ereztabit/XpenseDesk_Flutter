import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/admin_company_row.dart';
import '../../theme/app_theme.dart';

/// Payment-status pill in the companies table.
///
/// The state itself is decided by [AdminCompanyRow.displayStatus] — this widget
/// only paints it. Payment state is never re-derived here; the server's
/// `fn_GetSubscriptionStatus` result is what is shown.
class AdminCompanyStatusBadge extends StatelessWidget {
  const AdminCompanyStatusBadge({super.key, required this.company});

  final AdminCompanyRow company;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (String label, Color color) = switch (company.displayStatus) {
      AdminCompanyDisplayStatus.deactivated => (
          l10n.adminCompanyDeactivated,
          AppTheme.destructive,
        ),
      AdminCompanyDisplayStatus.pendingPayment => (
          l10n.adminPaymentStatusPendingPayment,
          AppTheme.amber,
        ),
      AdminCompanyDisplayStatus.active => (
          l10n.adminPaymentStatusActive,
          AppTheme.success,
        ),
      AdminCompanyDisplayStatus.inactive => (
          l10n.adminPaymentStatusInactive,
          AppTheme.mutedForeground,
        ),
      // Unrecognised server value — show it verbatim rather than guess.
      AdminCompanyDisplayStatus.unknown => (
          company.paymentStatus,
          AppTheme.mutedForeground,
        ),
    };

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withAlpha(102)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
