import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/budget.dart';
import '../../models/company_module.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_modules_provider.dart';
import '../../utils/format_utils.dart';
import '../last_action_confirm_dialog.dart';

/// Left-to-right isolate around the amount inside the (possibly RTL) sentence.
final String _lri = String.fromCharCode(0x2066);
final String _pdi = String.fromCharCode(0x2069);

/// FS-1013 PC-2: true to go on with an edit of [budget] to [newAmount].
/// Asks first only when the amount changed and leaves the balance below zero
/// while the company allows that; when it does not, the edit goes on and the
/// server's `BudgetAmountBelowSpent` refusal is shown in the dialog instead.
Future<bool> confirmBudgetBelowZero(
  BuildContext context,
  WidgetRef ref,
  Budget budget,
  double newAmount,
) async {
  if (newAmount == budget.initialAmount) return true;
  final over = budget.spentAmount - newAmount;
  if (over <= 0) return true;
  final allowed = ref
          .read(companyModulesProvider)
          .where((m) => m.key == CompanyModuleKey.pettyCash)
          .firstOrNull
          ?.allowNegativeBalance ??
      false;
  if (!allowed) return true;

  final l10n = AppLocalizations.of(context)!;
  final amount = over.toCurrency(ref.read(companyLocaleProvider), budget.currencyCode);
  return LastActionConfirmDialog.show(
    context,
    title: l10n.budgetsNegativeTitle,
    body: '${l10n.budgetsNegativeBody} $_lri$amount$_pdi ${l10n.budgetsNegativeBodyEnd}\n'
        '${l10n.budgetsNegativeAsk}',
  );
}
