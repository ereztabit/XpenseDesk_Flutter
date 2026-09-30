import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/free_receipts_provider.dart';
import '../../utils/app_navigator.dart';
import '../../utils/free_receipts_utils.dart';
import '../../utils/responsive_utils.dart';
import '../app_button.dart';
import '../bulk_upload/bulk_upload_amber_notice.dart';

/// The amber free-receipts callout (UI/UX guide §9.3–§9.4), on the shared
/// [BulkUploadAmberNotice]: "Your account is limited to 20 free receipts…" when
/// [onlyLeft] is null, or "Only 5 free receipts left" when a batch would go
/// past what is left. A manager gets "Upgrade now", which opens the billing
/// tab; an employee can't upgrade (the billing screen is manager-only), so they
/// get the sentence that points at the company's manager and no button.
///
/// One row with the button at the end on desktop, stacked on mobile.
/// [onUpgrade] runs first and may cancel: the bulk dialog asks before leaving
/// uploads in flight, and returns false when the user stays.
class FreeReceiptsCallout extends ConsumerWidget {
  const FreeReceiptsCallout({super.key, this.onlyLeft, this.onUpgrade});

  final int? onlyLeft;
  final Future<bool> Function()? onUpgrade;

  static const _billingRoute = '${AppRoutes.managerCompanyConfig}?tab=billing';

  Future<void> _upgrade(BuildContext context) async {
    // Taken before any await: the dialog this sits in may be gone after it.
    final navigator = Navigator.of(context, rootNavigator: true);
    final proceed = await (onUpgrade?.call() ?? Future.value(true));
    if (proceed) navigator.pushNamed(_billingRoute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isManager =
        ref.watch(userInfoProvider.select((u) => u?.isManager)) ?? false;
    final allowance =
        ref.watch(currentFreeReceiptsProvider.select((f) => f.allowance));
    final left = onlyLeft;

    return BulkUploadAmberNotice(
      message: left == null
          ? freeReceiptsUsedUpText(l10n,
              isManager: isManager, allowance: allowance)
          : freeReceiptsOnlyLeftText(l10n, left),
      showIcon: true,
      radius: 12,
      fontSize: 14,
      iconSize: 16,
      stackAction: context.isMobile,
      action: isManager
          ? AppButton(
              label: l10n.freeReceiptsUpgrade,
              icon: Icons.auto_awesome,
              dense: true,
              onPressed: () => _upgrade(context),
            )
          : null,
    );
  }
}
