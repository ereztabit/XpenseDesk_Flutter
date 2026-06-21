import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../services/tranzila_popup_service.dart';
import '../../theme/app_theme.dart';
import '../../models/company_billing.dart';
import '../../models/company_info.dart';
import '../../providers/billing_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/format_utils.dart';
import '../app_button.dart';
import '../plan_selection/plan_card.dart';
import '../plan_selection/coupon_section.dart';
import 'resume_subscription_dialog.dart';
import 'switch_plan_dialog.dart';

/// Renders the Current Plan card. Watches companyProvider for trial state.
class BillingCurrentPlanCard extends ConsumerWidget {
  const BillingCurrentPlanCard({
    super.key,
    required this.billing,
  });

  final CompanyBilling billing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final companyAsync = ref.watch(companyProvider);
    final company = companyAsync.whenOrNull(data: (c) => c);

    final subscription = billing.subscription;
    if (subscription == null) {
      return _NoPlanCard(l10n: l10n, company: company);
    }
    final pm = billing.paymentMethod;
    final hasValidPayment = pm != null && (pm.isActive || pm.isExpiringSoon);
    return _PlanCard(
      subscription: subscription,
      billing: billing,
      company: company,
      canResume: hasValidPayment,
      l10n: l10n,
      locale: ref.watch(companyLocaleProvider),
    );
  }
}

// ─── Current Plan card ───────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.subscription,
    required this.billing,
    this.company,
    required this.canResume,
    required this.l10n,
    required this.locale,
  });

  final BillingSubscription subscription;
  final CompanyBilling billing;
  final CompanyInfo? company;
  /// True only when a valid payment method exists (not null, not expired, not declined).
  final bool canResume;
  final AppLocalizations l10n;
  final String locale;

  bool get _isInTrial => company?.isInTrial ?? false;

  void _showSwitchDialog(BuildContext context, BillingSubscription sub) {
    showDialog<bool>(
      context: context,
      builder: (_) => SwitchPlanDialog(subscription: sub),
    );
  }

  void _showResumeDialog(BuildContext context, BillingSubscription sub) {
    showDialog<bool>(
      context: context,
      builder: (_) => ResumeSubscriptionDialog(subscription: sub),
    );
  }

  String _planDisplayName() {
    switch (subscription.planId) {
      case 1:
        return l10n.billingPlanAnnual;
      case 2:
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
            // Card title + status badge
            Row(
              children: [
                Text(
                  l10n.billingCurrentPlan,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_isInTrial)
                  _TrialBadge(l10n: l10n)
                else if (subscription.isActive)
                  _ActiveBadge(l10n: l10n)
                else if (subscription.isCancelled)
                  _CancelledBadge(l10n: l10n),
              ],
            ),
            const SizedBox(height: 16),

            // Plan info block
            _PlanInfoBlock(
              subscription: subscription,
              billing: billing,
              company: company,
              planDisplayName: _planDisplayName(),
              l10n: l10n,
              locale: locale,
            ),

            // Next Charge box — trial + active subscription (committed during trial).
            // The first-charge date is the server's subscription.startDate (the day
            // the paid period begins, already accounting for the trial + any free
            // months). Falls back to trialEndDate for older payloads without it.
            // Do NOT add a day — startDate is the authoritative charge date.
            if (_isInTrial &&
                subscription.isActive &&
                company?.trialEndDate != null) ...[
              const SizedBox(height: 12),
              _NextChargeBox(
                planDisplayName: _planDisplayName(),
                chargeDate: subscription.startDate ?? company!.trialEndDate!,
                chargeAmount: subscription.nextChargeAmount,
                l10n: l10n,
                locale: locale,
                currencyCode: company!.currencyCode,
              ),
            ],

            // Free months promo banner (not during trial — coupon shown in plan info)
            if (!_isInTrial &&
                subscription.isActive &&
                subscription.hasFreeMonths) ...[
              const SizedBox(height: 12),
              _FreeMonthsBanner(
                count: subscription.freeMonthsRemaining,
                l10n: l10n,
              ),
            ],

            // Upgrade prompt — monthly + active + not in trial + no pending switch + valid payment
            if (!_isInTrial &&
                subscription.isActive &&
                subscription.planId == 2 &&
                !subscription.hasPendingSwitch &&
                canResume) ...[
              const SizedBox(height: 12),
              _UpgradePromptBanner(
                l10n: l10n,
                subscription: subscription,
                annualPrice: company?.annualPlan?.price,
                monthlyPrice: company?.monthlyPlan?.price,
                symbol: company?.currencySymbol ?? '',
                locale: locale,
              ),
            ],

            // Downgrade button — annual + active + not in trial + no pending switch
            if (!_isInTrial &&
                subscription.isActive &&
                subscription.planId == 1 &&
                !subscription.hasPendingSwitch) ...[
              const SizedBox(height: 12),
              AppButton(
                label: l10n.billingSwitchToMonthlyButton,
                variant: AppButtonVariant.normal,
                onPressed: () => _showSwitchDialog(context, subscription),
              ),
            ],

            // Pending switch banner
            if (subscription.hasPendingSwitch) ...[
              const SizedBox(height: 12),
              _PendingSwitchBanner(
                futurePlan: subscription.futurePlan!,
                currentPlanId: subscription.planId,
                l10n: l10n,
                locale: locale,
              ),
            ],

            // Resume button — cancelled state only
            if (subscription.isCancelled) ...[
              const SizedBox(height: 16),
              AppButton(
                label: l10n.billingResumeSubscription,
                variant: AppButtonVariant.primary,
                onPressed: canResume
                    ? () => _showResumeDialog(context, subscription)
                    : null,
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
    required this.billing,
    this.company,
    required this.planDisplayName,
    required this.l10n,
    required this.locale,
  });

  final BillingSubscription subscription;
  final CompanyBilling billing;
  final CompanyInfo? company;
  final String planDisplayName;
  final AppLocalizations l10n;
  final String locale;

  bool get _isInTrial => company?.isInTrial ?? false;

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
          // --- Trial state ---
          if (_isInTrial) ...[
            _buildTrialInfo(),
            if (subscription.hasFreeMonths) ...[
              const SizedBox(height: 8),
              _buildCouponLine(),
            ],
          ]
          // --- Active state ---
          else if (subscription.isActive) ...[
            _buildActivePlanInfo(),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 12),
            _InfoRow(
              label: l10n.billingNextCharge,
              value: subscription.nextChargeAmount
                  .toSmartCurrency(locale, company?.currencyCode ?? 'ILS'),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: l10n.billingRenewsOn,
              value: subscription.endDate.toMediumDate(locale),
            ),
          ]
          // --- Cancelled state ---
          else if (subscription.isCancelled) ...[
            Text(
              planDisplayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 12),
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

  /// "Free Trial - ends Apr 20, 2026 (13 days)" in amber
  Widget _buildTrialInfo() {
    final trialEnd = company?.trialEndDate;
    final daysLeft = company?.trialDaysRemaining ?? 0;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: l10n.billingFreeTrial,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (trialEnd != null) ...[
            TextSpan(
              text: ' - ${l10n.billingFreeTrialEnds} ${trialEnd.toMediumDate(locale)} ($daysLeft ${l10n.billingFreeTrialDays})',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF92400E), // amber-800
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// "🏷️ 1 free month(s) applied until [date]" in green
  Widget _buildCouponLine() {
    final trialEnd = company?.trialEndDate;
    String couponEndStr = '';
    if (trialEnd != null) {
      final couponEnd = DateTime(
        trialEnd.year,
        trialEnd.month + subscription.freeMonthsRemaining,
        trialEnd.day,
      );
      couponEndStr = ' ${l10n.billingFreeMonthsUntil} ${couponEnd.toMediumDate(locale)}';
    }
    return Row(
      children: [
        const Icon(Icons.local_offer, size: 16, color: AppTheme.success),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '${subscription.freeMonthsRemaining} ${l10n.billingFreeMonthsApplied}$couponEndStr',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// "Monthly Plan - Last charged $30 on Apr 1, 2026"
  Widget _buildActivePlanInfo() {
    final lastChargeDate = billing.paymentMethod?.lastTransactionDate;
    if (lastChargeDate != null) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: planDisplayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: ' - ${l10n.billingLastCharged} ${subscription.nextChargeAmount.toSmartCurrency(locale, company?.currencyCode ?? 'ILS')} ${l10n.billingLastChargedOn} ${lastChargeDate.toMediumDate(locale)}',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }
    return Text(
      planDisplayName,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
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

// ─── Next Charge box ─────────────────────────────────────────────────────────

/// Tinted box showing what will be charged next: plan, date, amount.
/// Currently used only for trial-with-commitment states. Active subscription
/// states still render their charge info inside [_PlanInfoBlock].
class _NextChargeBox extends StatelessWidget {
  const _NextChargeBox({
    required this.planDisplayName,
    required this.chargeDate,
    required this.chargeAmount,
    required this.l10n,
    required this.locale,
    required this.currencyCode,
  });

  final String planDisplayName;
  final DateTime chargeDate;
  final double chargeAmount;
  final AppLocalizations l10n;
  final String locale;
  final String currencyCode;

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
          Text(
            l10n.billingNextCharge,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),
          _InfoRow(
            label: l10n.billingNextChargePlan,
            value: planDisplayName,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: l10n.billingNextChargeDate,
            value: chargeDate.toMediumDate(locale),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: l10n.billingNextChargeAmount,
            value: chargeAmount.toSmartCurrency(locale, currencyCode),
          ),
        ],
      ),
    );
  }
}

// ─── Active badge ────────────────────────────────────────────────────────────

class _TrialBadge extends StatelessWidget {
  const _TrialBadge({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.amber.withAlpha(25),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppTheme.amber.withAlpha(77)),
      ),
      child: Text(
        l10n.billingBadgeTrial,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF92400E), // amber-800
        ),
      ),
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
  const _UpgradePromptBanner({
    required this.l10n,
    required this.subscription,
    required this.annualPrice,
    required this.monthlyPrice,
    required this.symbol,
    required this.locale,
  });

  final AppLocalizations l10n;
  final BillingSubscription subscription;

  /// Server-driven plan prices from GET /api/company. Null only for older
  /// payloads with no plans array — the banner then drops the price fragments.
  final double? annualPrice;
  final double? monthlyPrice;
  final String symbol;
  final String locale;

  @override
  State<_UpgradePromptBanner> createState() => _UpgradePromptBannerState();
}

class _UpgradePromptBannerState extends State<_UpgradePromptBanner> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final annual = widget.annualPrice;
    final monthly = widget.monthlyPrice;

    // Title with annual savings (monthly x 12 - annual); subtitle with the
    // annual price. Both server-driven; fall back to price-less copy when the
    // plans array is unavailable.
    final annualStr =
        annual?.toCurrencyWithSymbol(widget.locale, widget.symbol);
    final savingsStr = (annual != null && monthly != null)
        ? (monthly * 12 - annual).toCurrencyWithSymbol(widget.locale, widget.symbol)
        : null;
    final title = savingsStr != null
        ? '${l10n.billingUpgradeSave} $savingsStr${l10n.perYear}'
        : l10n.billingUpgradeTitle;
    final subtitle = annualStr != null
        ? '$annualStr${l10n.perYear} · ${l10n.billingUpgradeSubtitle}'
        : l10n.billingUpgradeSubtitle;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => showDialog<bool>(
          context: context,
          builder: (_) => SwitchPlanDialog(subscription: widget.subscription),
        ),
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
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
    required this.currentPlanId,
    required this.l10n,
    required this.locale,
  });

  final BillingFuturePlan futurePlan;
  final int currentPlanId;
  final AppLocalizations l10n;
  final String locale;

  @override
  ConsumerState<_PendingSwitchBanner> createState() =>
      _PendingSwitchBannerState();
}

class _PendingSwitchBannerState extends ConsumerState<_PendingSwitchBanner> {
  bool _cancelling = false;

  /// Free plan (planId 3): the future plan is required (coupon period ends → paid plan kicks in).
  /// The API returns FUTURE_PLAN_NOT_CANCELLABLE for this case, so hide the button.
  bool get _canCancel => widget.currentPlanId != 3;

  Future<void> _handleCancel() async {
    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(widget.l10n.billingCancelScheduledChange),
        content: Text(widget.l10n.billingCancelScheduledChangeConfirm),
        actions: [
          AppButton(
            label: widget.l10n.billingDoNothing,
            variant: AppButtonVariant.normal,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          AppButton(
            label: widget.l10n.billingCancelScheduledChange,
            variant: AppButtonVariant.destructive,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

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
    switch (widget.futurePlan.planId) {
      case 1:
        return widget.l10n.billingPlanAnnualShort;
      case 2:
        return widget.l10n.billingPlanMonthlyShort;
      default:
        return widget.futurePlan.planName.toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Future-plan charge from the API, formatted in the company currency.
    final symbol =
        ref.watch(companyProvider).asData?.value.currencySymbol ?? '';
    final amount =
        widget.futurePlan.chargeAmount.toCurrencyWithSymbol(widget.locale, symbol);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withAlpha(51)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.access_time_outlined, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.l10n.billingPendingSwitchTo} ${_futurePlanShortName()} '
                  '${widget.l10n.billingPendingSwitchCost} $amount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.l10n.billingPendingSwitchOn} '
                  '${widget.futurePlan.startDate.toMediumDate(widget.locale)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          if (_canCancel) ...[
            const SizedBox(width: 12),
            _cancelling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : AppButton(
                    label: widget.l10n.billingCancelScheduledChange,
                    variant: AppButtonVariant.destructive,
                    onPressed: _handleCancel,
                  ),
          ],
        ],
      ),
    );
  }
}

// ─── No plan yet ─────────────────────────────────────────────────────────────

class _NoPlanCard extends ConsumerStatefulWidget {
  const _NoPlanCard({required this.l10n, this.company});

  final AppLocalizations l10n;
  final CompanyInfo? company;

  @override
  ConsumerState<_NoPlanCard> createState() => _NoPlanCardState();
}

class _NoPlanCardState extends ConsumerState<_NoPlanCard> {
  /// Selected billingPlanId; null until the user taps (defaults to annual).
  int? _selectedPlanId;
  String? _couponCode;
  final _couponKey = GlobalKey<CouponSectionState>();
  bool _busy = false;
  String? _errorMessage;
  TranzilaPopupService? _popupService;

  // Captured from context in didChangeDependencies — safe to use in async
  // callbacks that fire from dart:html postMessage after the widget tree
  // may have been torn down.
  late NavigatorState _navigator;
  late String _failMsg;
  late String _popupBlockedMsg;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _navigator = Navigator.of(context);
    _failMsg = l10n.subscriptionCreationFailed;
    _popupBlockedMsg = l10n.billingPopupBlocked;

    if (_popupService == null) {
      _initPopupService();
    }
  }

  void _initPopupService() {
    final userInfo = ref.read(userInfoProvider);
    _popupService = TranzilaPopupService(
      authService: ref.read(authServiceProvider),
      userFullName: userInfo?.fullName ?? '',
      userEmail: userInfo?.email ?? '',
      userDialingCode: userInfo?.dailingCode ?? '',
    );
    _popupService!.onResult = _onTranzilaResult;
    _popupService!.onPopupBlocked = () {
      if (!mounted) return;
      setState(() {
        _errorMessage = _popupBlockedMsg;
        _busy = false;
      });
    };
    _popupService!.onError = (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _failMsg;
        _busy = false;
      });
    };
    _popupService!.startListening();
  }

  @override
  void dispose() {
    _popupService?.dispose();
    super.dispose();
  }

  Future<void> _handleProceed() async {
    if (_busy) return;
    // Read context-derived values up front — the coupon validation below awaits.
    final lang = Localizations.localeOf(context).languageCode;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    // Auto-apply a coupon the user typed but never pressed Apply on. If it's
    // invalid, abort before opening payment — the section shows the inline error.
    final couponOk = await _couponKey.currentState?.applyPendingCoupon() ?? true;
    if (!couponOk) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    await _popupService!.openPopup(lang: lang);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _onTranzilaResult(TranzilaPopupResult result) async {
    if (!result.success) {
      if (!mounted) return;
      setState(() {
        _errorMessage = result.error ?? _failMsg;
      });
      return;
    }

    if (mounted) setState(() => _busy = true);

    try {
      final planId =
          _selectedPlanId ?? widget.company?.defaultPlan?.billingPlanId;
      if (planId == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = _failMsg;
          _busy = false;
        });
        return;
      }
      final authService = ref.read(authServiceProvider);
      await authService.createSubscription(
        paymentProviderResponse: result.tranzilaResponse,
        billingPlanId: planId,
        couponCode: _couponCode,
      );
    } catch (e) {
      debugPrint('[NoPlanCard] createSubscription failed: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = _failMsg;
        _busy = false;
      });
      return;
    }

    // Subscription created — navigate to dashboard.
    // Navigate FIRST, then invalidate. This avoids the deactivated-widget
    // race where invalidate tears down the widget tree before navigate runs.
    try {
      _navigator.pushNamedAndRemoveUntil('/dashboard', (route) => false);
      ref.invalidate(companyProvider);
    } catch (_) {
      // Widget tree already torn down — verify status and force navigate.
      try {
        final company = await ref.read(authServiceProvider).getCompany();
        if (company.subscriptionStatus == 'Active') {
          _navigator.pushNamedAndRemoveUntil('/dashboard', (route) => false);
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

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
            // Title
            Text(
              l10n.choosePlan,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            // Trial info — shown when user is in trial
            if (widget.company?.isInTrial == true) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.amber.withAlpha(77)),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.billingTrialDaysLeft +
                          (widget.company?.trialDaysRemaining ?? 0).toString() +
                          l10n.billingTrialDaysLeftSuffix,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E), // amber-800
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.billingTrialChargeNote,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Plan cards
            _buildPlanCards(l10n),
            const SizedBox(height: 24),

            // Coupon section
            CouponSection(
              key: _couponKey,
              onCouponResult: (code) {
                setState(() => _couponCode = code);
              },
            ),
            const SizedBox(height: 24),

            // Inline error
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.destructive.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.destructive.withAlpha(77)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.destructive,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Proceed button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: l10n.proceedToPayment,
                variant: AppButtonVariant.primary,
                isLoading: _busy,
                onPressed: _handleProceed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCards(AppLocalizations l10n) {
    final company = widget.company;
    final locale = ref.watch(companyLocaleProvider);
    final plans = company?.displayPlans ?? const [];
    if (plans.isEmpty) {
      return Text(
        l10n.subscriptionCreationFailed,
        style: const TextStyle(fontSize: 13, color: AppTheme.destructive),
      );
    }
    final selectedId = _selectedPlanId ?? company?.defaultPlan?.billingPlanId;
    final symbol = company?.currencySymbol ?? '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < plans.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            Expanded(
              child: PlanCard(
                price: plans[i].price.toCurrencyWithSymbol(locale, symbol),
                period: plans[i].isMonthly ? l10n.perMonth : l10n.perYear,
                isSelected: selectedId == plans[i].billingPlanId,
                onTap: () =>
                    setState(() => _selectedPlanId = plans[i].billingPlanId),
                badgeLabel: plans[i].isAnnual ? l10n.bestValue : null,
                savingsLabel: plans[i].isAnnual ? l10n.savePercent : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

