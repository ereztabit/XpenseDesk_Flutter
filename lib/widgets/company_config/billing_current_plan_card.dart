import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../models/company_billing.dart';
import '../../providers/billing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/format_utils.dart';

/// Renders the Billing tab content for Story 2.
/// Watches [billingProvider] internally so it loads lazily when the tab
/// is first shown, not on screen entry.
class BillingCurrentPlanCard extends ConsumerWidget {
  const BillingCurrentPlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final billingAsync = ref.watch(billingProvider);

    return billingAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(64),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => _BillingErrorCard(
        message: l10n.billingFailedToLoad,
        retryLabel: l10n.retry,
        onRetry: () => ref.invalidate(billingProvider),
      ),
      data: (billing) {
        final subscription = billing.subscription;
        if (subscription == null) {
          return _NoPlanCard(l10n: l10n);
        }
        return _PlanCard(
          subscription: subscription,
          l10n: l10n,
          locale: ref.watch(companyLocaleProvider),
        );
      },
    );
  }
}

// ─── Current Plan card ───────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.subscription,
    required this.l10n,
    required this.locale,
  });

  final BillingSubscription subscription;
  final AppLocalizations l10n;
  final String locale;

  String _planDisplayName() {
    switch (subscription.planName.toLowerCase()) {
      case 'annual':
        return l10n.billingPlanAnnual;
      case 'monthly':
        return l10n.billingPlanMonthly;
      default:
        return subscription.planName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card title
            Text(
              l10n.billingCurrentPlan,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Plan info block
            _PlanInfoBlock(
              subscription: subscription,
              planDisplayName: _planDisplayName(),
              l10n: l10n,
              locale: locale,
            ),

            // Free months promo banner
            if (subscription.isActive && subscription.hasFreeMonths) ...[
              const SizedBox(height: 12),
              _FreeMonthsBanner(
                count: subscription.freeMonthsRemaining,
                l10n: l10n,
              ),
            ],

            // Upgrade prompt — monthly + active + no pending switch
            if (subscription.isActive &&
                subscription.planName.toLowerCase() == 'monthly' &&
                !subscription.hasPendingSwitch) ...[
              const SizedBox(height: 12),
              _UpgradePromptBanner(l10n: l10n),
            ],

            // Pending switch banner
            if (subscription.hasPendingSwitch) ...[
              const SizedBox(height: 12),
              _PendingSwitchBanner(
                futurePlan: subscription.futurePlan!,
                currentPlanName: subscription.planName,
                l10n: l10n,
                locale: locale,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Plan info block (the tinted inner box) ──────────────────────────────────

class _PlanInfoBlock extends StatelessWidget {
  const _PlanInfoBlock({
    required this.subscription,
    required this.planDisplayName,
    required this.l10n,
    required this.locale,
  });

  final BillingSubscription subscription;
  final String planDisplayName;
  final AppLocalizations l10n;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Plan name row (with optional status badge at trailing edge)
          Row(
            children: [
              Text(
                planDisplayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (subscription.isActive)
                _ActiveBadge(l10n: l10n)
              else if (subscription.isCancelled)
                _CancelledBadge(l10n: l10n),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),

          // Active state: two info rows
          if (subscription.isActive) ...[
            _InfoRow(
              label: l10n.billingRenewsOn,
              value: subscription.endDate.toMediumDate(locale),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: l10n.billingNextCharge,
              value: subscription.nextChargeAmount.toSmartCurrency(locale, 'USD'),
            ),
          ],

          // Cancelled state: two body text lines
          if (subscription.isCancelled) ...[
            Text.rich(
              TextSpan(
                text: '${l10n.billingSubscriptionActiveUntil} ',
                children: [
                  TextSpan(
                    text: subscription.endDate.toMediumDate(locale),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.billingSubscriptionNoAccess,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Info row (label + value) ─────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.mutedForeground,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Active badge ────────────────────────────────────────────────────────────

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.success.withAlpha(25),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppTheme.success.withAlpha(77)),
      ),
      child: Text(
        l10n.billingStatusActive,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.success,
        ),
      ),
    );
  }
}

// ─── Cancelled badge ──────────────────────────────────────────────────────────

class _CancelledBadge extends StatelessWidget {
  const _CancelledBadge({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withAlpha(25),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppTheme.destructive.withAlpha(77)),
      ),
      child: Text(
        l10n.billingStatusCancelled,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.destructive,
        ),
      ),
    );
  }
}

// ─── Upgrade prompt banner (monthly → annual) ────────────────────────────────

class _UpgradePromptBanner extends StatefulWidget {
  const _UpgradePromptBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_UpgradePromptBanner> createState() => _UpgradePromptBannerState();
}

class _UpgradePromptBannerState extends State<_UpgradePromptBanner> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        // Story 7 will wire this to the Switch Plan dialog
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(_hovered ? 25 : 13),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primary.withAlpha(77)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, size: 20, color: AppTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.l10n.billingUpgradeTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.l10n.billingUpgradeSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Free months promo banner ─────────────────────────────────────────────────

class _FreeMonthsBanner extends StatelessWidget {
  const _FreeMonthsBanner({required this.count, required this.l10n});

  final int count;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    const emerald = Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: emerald.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: emerald.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined, size: 16, color: emerald),
          const SizedBox(width: 8),
          Text(
            '$count ${l10n.billingFreeMonthsApplied}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: emerald,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pending switch banner ────────────────────────────────────────────────────

// ─── Pending switch banner ────────────────────────────────────────────────────

class _PendingSwitchBanner extends ConsumerStatefulWidget {
  const _PendingSwitchBanner({
    required this.futurePlan,
    required this.currentPlanName,
    required this.l10n,
    required this.locale,
  });

  final BillingFuturePlan futurePlan;
  final String currentPlanName;
  final AppLocalizations l10n;
  final String locale;

  @override
  ConsumerState<_PendingSwitchBanner> createState() =>
      _PendingSwitchBannerState();
}

class _PendingSwitchBannerState extends ConsumerState<_PendingSwitchBanner> {
  bool _cancelling = false;

  /// Free plan: the future plan is required (coupon period ends → paid plan kicks in).
  /// The API returns FUTURE_PLAN_NOT_CANCELLABLE for this case, so hide the button.
  bool get _canCancel =>
      widget.currentPlanName.toLowerCase() != 'free';

  Future<void> _handleCancel() async {
    setState(() => _cancelling = true);
    try {
      await ref.read(billingProvider.notifier).cancelFuturePlan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.l10n.billingScheduledChangeCancelled),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on Exception catch (_) {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  String _futurePlanShortName() {
    switch (widget.futurePlan.planName.toLowerCase()) {
      case 'annual':
        return widget.l10n.billingPlanAnnualShort;
      case 'monthly':
        return widget.l10n.billingPlanMonthlyShort;
      default:
        return widget.futurePlan.planName.toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_outlined, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.l10n.billingPendingSwitchTo} ${_futurePlanShortName()} '
              '${widget.l10n.billingPendingSwitchOn} '
              '${widget.futurePlan.startDate.toMediumDate(widget.locale)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primary,
              ),
            ),
          ),
          if (_canCancel) ...[
            const SizedBox(width: 8),
            _cancelling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : OutlinedButton(
                    onPressed: _handleCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(color: AppTheme.primary.withAlpha(128)),
                      foregroundColor: AppTheme.primary,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Text(widget.l10n.billingCancelScheduledChange),
                  ),
          ],
        ],
      ),
    );
  }
}

// ─── No plan yet ─────────────────────────────────────────────────────────────

class _NoPlanCard extends StatelessWidget {
  const _NoPlanCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.billingCurrentPlan,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.billingNoPlanYet,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error card ───────────────────────────────────────────────────────────────

class _BillingErrorCard extends StatelessWidget {
  const _BillingErrorCard({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline,
                color: AppTheme.destructive, size: 32),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
