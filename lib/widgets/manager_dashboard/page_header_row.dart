import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import 'employee_filter_dropdown.dart';

/// Page header for the Sheet Approvals screen.
///
/// Leading: title `sheetApprovals` ("Sheet Approvals").
/// Trailing: [EmployeeFilterDropdown] (160×32). No "+ New expense" button —
/// the Sheet Approvals screen is read-only.
class ManagerPageHeaderRow extends StatelessWidget {
  const ManagerPageHeaderRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderMedium, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n.sheetApprovals,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: context.isMobile ? 18 : 24,
                ),
          ),
          const EmployeeFilterDropdown(),
        ],
      ),
    );
  }
}
