import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../providers/billing_provider.dart';
import '../../utils/format_utils.dart';
import '../../providers/auth_provider.dart';
import '../app_button.dart';

/// Confirmation dialog for cancelling the subscription (Story 5).
class CancelSubscriptionDialog extends ConsumerStatefulWidget {
  const CancelSubscriptionDialog({
    super.key,
    required this.endDate,
  });

  final DateTime endDate;

  @override
  ConsumerState<CancelSubscriptionDialog> createState() =>
      _CancelSubscriptionDialogState();
}

class _CancelSubscriptionDialogState
    extends ConsumerState<CancelSubscriptionDialog> {
  bool _cancelling = false;
  String? _errorMessage;

  Future<void> _handleCancel() async {
    setState(() {
      _cancelling = true;
      _errorMessage = null;
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      await ref.read(billingProvider.notifier).cancelSubscription();
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.billingSubscriptionCancelled),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cancelling = false;
          _errorMessage = l10n.billingCancelFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);
    final formattedDate = widget.endDate.toMediumDate(locale);

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
                l10n.billingCancelDialogTitle,
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
                    Text.rich(
                      TextSpan(
                        text: '${l10n.billingCancelDialogActiveUntil} ',
                        children: [
                          TextSpan(
                            text: formattedDate,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.billingCancelDialogNoRenew,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.billingCancelDialogNoAccess,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Error
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppTheme.destructive,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Footer buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: l10n.billingKeepSubscription,
                    variant: AppButtonVariant.normal,
                    onPressed: _cancelling
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: l10n.billingCancelSubscription,
                    variant: AppButtonVariant.destructive,
                    isLoading: _cancelling,
                    onPressed: _handleCancel,
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
