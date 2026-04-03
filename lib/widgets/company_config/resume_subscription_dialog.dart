import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../models/company_billing.dart';
import '../../providers/billing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/format_utils.dart';
import '../../services/auth_service.dart';
import '../app_button.dart';

/// Confirmation dialog for resuming a cancelled subscription (Story 6).
/// Shows different content based on whether the billing period has expired.
class ResumeSubscriptionDialog extends ConsumerStatefulWidget {
  const ResumeSubscriptionDialog({
    super.key,
    required this.subscription,
  });

  final BillingSubscription subscription;

  @override
  ConsumerState<ResumeSubscriptionDialog> createState() =>
      _ResumeSubscriptionDialogState();
}

class _ResumeSubscriptionDialogState
    extends ConsumerState<ResumeSubscriptionDialog> {
  bool _resuming = false;
  String? _errorMessage;

  bool get _isExpired => widget.subscription.endDate.isBefore(DateTime.now());

  String _renewalCycle(AppLocalizations l10n) {
    switch (widget.subscription.planName.toLowerCase()) {
      case 'annual':
        return l10n.billingResumeAnnually;
      default:
        return l10n.billingResumeMonthly;
    }
  }

  Future<void> _handleResume() async {
    setState(() {
      _resuming = true;
      _errorMessage = null;
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      await ref.read(billingProvider.notifier).resumeSubscription();
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.billingSubscriptionReactivated),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _resuming = false;
          _errorMessage = '${l10n.billingResumePaymentFailed}: ${e.message}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resuming = false;
          _errorMessage = l10n.billingResumeFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);
    final amount = widget.subscription.nextChargeAmount
        .toSmartCurrency(locale, 'USD');
    final cycle = _renewalCycle(l10n);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                l10n.billingResumeDialogTitle,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.billingResumeReactivated,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    if (_isExpired) ...[
                      // Expired: charge today
                      Text.rich(
                        TextSpan(
                          text: '${l10n.billingResumeChargedToday} ',
                          children: [
                            TextSpan(
                              text: amount,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextSpan(
                                text: ' ${l10n.billingResumeChargedTodaySuffix}'),
                          ],
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.billingResumePlanStartNow} $cycle',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ] else ...[
                      // Still active: no charge
                      Text(
                        l10n.billingResumeNoChargeToday,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.billingResumePlanContinue} $cycle',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),

              // Error (inline — for payment failures)
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
                    onPressed: _resuming
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: l10n.billingResumeSubscription,
                    variant: AppButtonVariant.primary,
                    isLoading: _resuming,
                    onPressed: _handleResume,
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
