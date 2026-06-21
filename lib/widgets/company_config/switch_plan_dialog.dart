import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../models/company_billing.dart';
import '../../providers/billing_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/format_utils.dart';
import '../../services/auth_service.dart';
import '../app_button.dart';

/// Dialog for switching between Monthly and Annual plans (Story 7).
/// Upgrade (monthly → annual): immediate charge.
/// Downgrade (annual → monthly): effective at next renewal.
class SwitchPlanDialog extends ConsumerStatefulWidget {
  const SwitchPlanDialog({
    super.key,
    required this.subscription,
  });

  final BillingSubscription subscription;

  @override
  ConsumerState<SwitchPlanDialog> createState() => _SwitchPlanDialogState();
}

class _SwitchPlanDialogState extends ConsumerState<SwitchPlanDialog> {
  bool _switching = false;
  String? _errorMessage;

  bool get _isUpgrade =>
      widget.subscription.planName.toLowerCase() == 'monthly';

  Future<void> _handleConfirm() async {
    setState(() {
      _switching = true;
      _errorMessage = null;
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      if (_isUpgrade) {
        await ref.read(billingProvider.notifier).moveToAnnual();
      } else {
        await ref.read(billingProvider.notifier).moveToMonthly();
      }
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.billingPlanSwitched),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _switching = false;
          _errorMessage = '${l10n.billingSwitchPaymentFailed}: ${e.message}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _switching = false;
          _errorMessage = l10n.billingSwitchFailed;
        });
      }
    }
  }

  /// Formats the plan price from the company API. Falls back to the
  /// subscription's next charge amount if the plans array is unavailable
  /// (older payloads) — never a hardcoded literal.
  String _planAmount(double? planPrice, String symbol, String locale) {
    final value = planPrice ?? widget.subscription.nextChargeAmount;
    return value.toCurrencyWithSymbol(locale, symbol);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);
    final company = ref.watch(companyProvider).asData?.value;
    final symbol = company?.currencySymbol ?? '';
    final endDate = widget.subscription.endDate.toMediumDate(locale);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.primary.withAlpha(51)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                _isUpgrade
                    ? l10n.billingSwitchToAnnualTitle
                    : l10n.billingSwitchToMonthlyTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              // Content block
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.muted.withAlpha(77),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: _isUpgrade
                    ? _UpgradeContent(
                        l10n: l10n,
                        locale: locale,
                        amount: _planAmount(
                            company?.annualPlan?.price, symbol, locale),
                      )
                    : _DowngradeContent(
                        l10n: l10n,
                        endDate: endDate,
                        amount: _planAmount(
                            company?.monthlyPlan?.price, symbol, locale),
                      ),
              ),

              // Error
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.destructive.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.destructive, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.destructive,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Footer buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: l10n.cancel,
                    variant: AppButtonVariant.normal,
                    onPressed: _switching
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: _isUpgrade
                        ? l10n.billingSwitchConfirmUpgrade
                        : l10n.billingSwitchConfirmSwitch,
                    variant: AppButtonVariant.primary,
                    isLoading: _switching,
                    onPressed: _handleConfirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Upgrade content (monthly → annual) ─────────────────────────────────────

class _UpgradeContent extends StatelessWidget {
  const _UpgradeContent({
    required this.l10n,
    required this.locale,
    required this.amount,
  });

  final AppLocalizations l10n;
  final String locale;

  /// Annual plan price, server-driven and pre-formatted by the parent.
  final String amount;

  @override
  Widget build(BuildContext context) {
    // TODO(bug #8 / backend): the "starts on / renews on" dates are computed
    // naively as today + 1 year and ignore the already-paid period and any
    // remaining free months. The correct projected dates require a backend
    // switch-preview — see docs/bugs/billing-plan-switch-preview-charge-and-dates.md
    // in the server repo. Until then this date is approximate.
    final today = DateTime.now();
    final renewDate = DateTime(today.year + 1, today.month, today.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: '${l10n.billingSwitchUpgradeCharge} ',
            children: [
              TextSpan(
                text: amount,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(text: ' ${l10n.billingSwitchUpgradeChargeToday}'),
            ],
          ),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: '${l10n.billingSwitchUpgradeStartsOn} ',
            children: [
              TextSpan(
                text: today.toMediumDate(locale),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(text: ' ${l10n.billingSwitchUpgradeRenewsOn} '),
              TextSpan(
                text: renewDate.toMediumDate(locale),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.billingSwitchUpgradeMonthlyStops,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

// ─── Downgrade content (annual → monthly) ───────────────────────────────────

class _DowngradeContent extends StatelessWidget {
  const _DowngradeContent({
    required this.l10n,
    required this.endDate,
    required this.amount,
  });

  final AppLocalizations l10n;
  final String endDate;

  /// Monthly plan price, server-driven and pre-formatted by the parent.
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: '${l10n.billingSwitchDowngradeActiveUntil} ',
            children: [
              TextSpan(
                text: endDate,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: '${l10n.billingSwitchDowngradeMonthlyBegins} ',
            children: [
              TextSpan(
                text: amount,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(text: ' ${l10n.billingSwitchDowngradeWillBeginOn} '),
              TextSpan(
                text: endDate,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
