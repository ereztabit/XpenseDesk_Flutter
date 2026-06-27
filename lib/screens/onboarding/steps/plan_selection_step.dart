import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_config.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../models/company_info.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/company_provider.dart';
import '../../../services/tranzila_popup_service.dart';
import '../../../utils/format_utils.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/plan_selection/plan_card.dart';
import '../../../widgets/plan_selection/coupon_section.dart';

/// Onboarding Step 4 — Plan Selection + Payment.
///
/// Reuses [PlanCard] and [CouponSection] from the shared widgets.
/// "Proceed to Payment" opens the Tranzila popup (same as billing tab).
/// "Skip for now" navigates straight to the dashboard (trial mode).
class PlanSelectionStep extends ConsumerStatefulWidget {
  const PlanSelectionStep({super.key});

  @override
  ConsumerState<PlanSelectionStep> createState() => _PlanSelectionStepState();
}

class _PlanSelectionStepState extends ConsumerState<PlanSelectionStep> {
  int? _selectedPlanId;
  String? _couponCode;
  final _couponKey = GlobalKey<CouponSectionState>();
  bool _busy = false;
  String? _errorMessage;
  TranzilaPopupService? _popupService;

  // Captured from context in didChangeDependencies — safe to use in async
  // callbacks that fire after the widget tree may have been torn down.
  late NavigatorState _navigator;
  late String _failMsg;
  late String _popupBlockedMsg;

  @override
  void initState() {
    super.initState();
    // Req: (re)fetch the company — with server-driven plans/prices — before the
    // prices screen renders, so the cards show the right amounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(companyProvider.notifier).refresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _navigator = Navigator.of(context);
    _failMsg = l10n.subscriptionCreationFailed;
    _popupBlockedMsg = l10n.billingPopupBlocked;

    // Init popup service here — needs context-derived values
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
      final company = ref.read(companyProvider).asData?.value;
      final planId = _selectedPlanId ?? company?.defaultPlan?.billingPlanId;
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

      ref.read(analyticsServiceProvider).trackEvent('onboarding_payment_added');
    } catch (e) {
      debugPrint('[PlanSelectionStep] createSubscription failed: $e');
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
      _completeOnboarding();
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

  void _skipForNow() {
    ref.read(analyticsServiceProvider).trackEvent('onboarding_payment_skipped');
    _completeOnboarding();
  }

  /// Fires the one-time company_created event, then routes to the dashboard.
  /// Both onboarding exits (paid + skipped) go through here, so the event fires
  /// exactly once when a freshly created company lands on the dashboard.
  void _completeOnboarding() {
    ref.read(analyticsServiceProvider).trackEvent('company_created');
    _navigator.pushNamedAndRemoveUntil('/dashboard', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final companyAsync = ref.watch(companyProvider);

    return companyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _errorBox(l10n.subscriptionCreationFailed),
      data: (company) => _buildForm(context, l10n, company),
    );
  }

  Widget _buildForm(
      BuildContext context, AppLocalizations l10n, CompanyInfo company) {
    final locale = ref.watch(companyLocaleProvider);
    final plans = company.displayPlans;
    final selectedId = _selectedPlanId ?? company.defaultPlan?.billingPlanId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Static trial message — trial length comes from config, not a literal
        Text(
          '${l10n.plansIncludeTrialPrefix}${AppConfig.instance.trialDays}${l10n.plansIncludeTrialSuffix}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 24),

        // Plan cards — server-driven, side by side
        if (plans.isEmpty)
          _errorBox(l10n.subscriptionCreationFailed)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < plans.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(
                  child: PlanCard(
                    price: plans[i]
                        .price
                        .toCurrencyWithSymbol(locale, company.currencySymbol),
                    period: plans[i].isMonthly ? l10n.perMonth : l10n.perYear,
                    isSelected: selectedId == plans[i].billingPlanId,
                    onTap: () => setState(
                        () => _selectedPlanId = plans[i].billingPlanId),
                  ),
                ),
              ],
            ],
          ),
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
          _errorBox(_errorMessage!),
          const SizedBox(height: 16),
        ],

        // Proceed to Payment
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: l10n.proceedToPayment,
            variant: AppButtonVariant.primary,
            isLoading: _busy,
            onPressed: _handleProceed,
          ),
        ),
        const SizedBox(height: 12),

        // Skip for now
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: l10n.skipForNow,
            variant: AppButtonVariant.ghost,
            onPressed: _busy ? null : _skipForNow,
          ),
        ),
      ],
    );
  }

  Widget _errorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.destructive.withAlpha(77)),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: AppTheme.destructive),
      ),
    );
  }
}
