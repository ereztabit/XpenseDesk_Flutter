import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../services/tranzila_popup_service.dart';
import '../../theme/app_theme.dart';
import '../../models/company_billing.dart';
import '../../providers/billing_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/format_utils.dart';
import '../app_button.dart';
import '../plan_selection/plan_card.dart';
import '../plan_selection/coupon_section.dart';
import 'resume_subscription_dialog.dart';
import 'switch_plan_dialog.dart';

/// Renders the Current Plan card. Data is passed in — no provider watching here.
class BillingCurrentPlanCard extends ConsumerWidget {
  const BillingCurrentPlanCard({
    super.key,
    required this.billing,
  });

  final CompanyBilling billing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final subscription = billing.subscription;
    if (subscription == null) {
      return _NoPlanCard(l10n: l10n);
    }
    final pm = billing.paymentMethod;
    final hasValidPayment = pm != null && (pm.isActive || pm.isExpiringSoon);
    return _PlanCard(
      subscription: subscription,
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
    required this.canResume,
    required this.l10n,
    required this.locale,
  });

  final BillingSubscription subscription;
  /// True only when a valid payment method exists (not null, not expired, not declined).
  final bool canResume;
  final AppLocalizations l10n;
  final String locale;

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

            // Upgrade prompt — monthly + active + no pending switch + valid payment
            if (subscription.isActive &&
                subscription.planName.toLowerCase() == 'monthly' &&
                !subscription.hasPendingSwitch &&
                canResume) ...[
              const SizedBox(height: 12),
              _UpgradePromptBanner(
                l10n: l10n,
                subscription: subscription,
              ),
            ],

            // Downgrade button — annual + active + no pending switch
            if (subscription.isActive &&
                subscription.planName.toLowerCase() == 'annual' &&
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
                currentPlanName: subscription.planName,
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
  const _UpgradePromptBanner({
    required this.l10n,
    required this.subscription,
  });

  final AppLocalizations l10n;
  final BillingSubscription subscription;

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
                  '${widget.l10n.billingPendingSwitchTo} ${_futurePlanShortName()}',
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
  const _NoPlanCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  ConsumerState<_NoPlanCard> createState() => _NoPlanCardState();
}

class _NoPlanCardState extends ConsumerState<_NoPlanCard> {
  /// Matches config planId values. Defaults to annual.
  late int _selectedPlanId;
  String? _couponCode;
  bool _busy = false;
  String? _errorMessage;
  TranzilaPopupService? _popupService;

  @override
  void initState() {
    super.initState();
    _selectedPlanId = AppConfig.instance.annualPlanId;
    _initPopupService();
  }

  void _initPopupService() {
    debugPrint('[NoPlanCard] _initPopupService — setting up Tranzila listener');
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
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.billingPopupBlocked;
        _busy = false;
      });
    };
    _popupService!.onError = (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.subscriptionCreationFailed;
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
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    final lang = Localizations.localeOf(context).languageCode;
    await _popupService!.openPopup(lang: lang);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _onTranzilaResult(TranzilaPopupResult result) async {
    debugPrint('[NoPlanCard] onTranzilaResult: success=${result.success} token=${result.token} error=${result.error}');
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    if (!result.success) {
      setState(() {
        _errorMessage = result.error ?? l10n.subscriptionCreationFailed;
      });
      return;
    }

    // Card tokenized successfully → create subscription
    debugPrint('[NoPlanCard] Card tokenized OK — creating subscription planId=$_selectedPlanId coupon=$_couponCode');
    setState(() => _busy = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.createSubscription(
        paymentProviderResponse: result.tranzilaResponse,
        billingPlanId: _selectedPlanId,
        couponCode: _couponCode,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.subscriptionCreatedSuccess),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Refresh company data so dashboard sees subscriptionStatus = Active
      ref.invalidate(companyProvider);

      // Navigate to dashboard
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/dashboard',
        (route) => false,
      );
    } catch (e) {
      debugPrint('[NoPlanCard] createSubscription error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = l10n.subscriptionCreationFailed;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final config = AppConfig.instance;

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
            const SizedBox(height: 24),

            // Plan cards
            _buildPlanCards(l10n, config),
            const SizedBox(height: 24),

            // Coupon section
            CouponSection(
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

  Widget _buildPlanCards(AppLocalizations l10n, AppConfig config) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: PlanCard(
              price: '\$${config.monthlyPrice}',
              period: l10n.perMonth,
              isSelected: _selectedPlanId == config.monthlyPlanId,
              onTap: () =>
                  setState(() => _selectedPlanId = config.monthlyPlanId),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: PlanCard(
              price: '\$${config.annualPrice}',
              period: l10n.perYear,
              isSelected: _selectedPlanId == config.annualPlanId,
              onTap: () =>
                  setState(() => _selectedPlanId = config.annualPlanId),
              badgeLabel: l10n.bestValue,
              savingsLabel: l10n.savePercent,
            ),
          ),
        ],
      ),
    );
  }
}

