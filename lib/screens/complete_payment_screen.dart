import 'screen_imports.dart';
import '../utils/responsive_utils.dart';
import '../widgets/header/login_header.dart';
import '../widgets/plan_selection/plan_card.dart';
import '../widgets/plan_selection/coupon_section.dart';
import '../widgets/app_button.dart';

/// Plan selection + coupon entry screen.
/// Reached from Billing "No Plan" CTA or the amber PendingPayment banner.
class CompletePaymentScreen extends ConsumerStatefulWidget {
  const CompletePaymentScreen({super.key});

  @override
  ConsumerState<CompletePaymentScreen> createState() =>
      _CompletePaymentScreenState();
}

class _CompletePaymentScreenState extends ConsumerState<CompletePaymentScreen>
    with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

  /// null = no selection, 1 = annual, 2 = monthly
  int? _selectedPlanId;

  /// Coupon state
  String? _couponCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isNarrow = context.isNarrow;

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const LoginHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ConstrainedContent(
                  maxWidth: 672,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppButton(
                          label: l10n.backToDashboard,
                          variant: AppButtonVariant.ghost,
                          icon: Icons.arrow_back,
                          onPressed: () =>
                              Navigator.of(context).pushNamedAndRemoveUntil(
                            '/dashboard',
                            (route) => false,
                          ),
                        ),
                      ),

                      // Main card
                      Card(
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
                              _buildPlanCards(l10n, isNarrow),
                              const SizedBox(height: 24),

                              // Coupon section
                              CouponSection(
                                onCouponResult: (code) {
                                  setState(() => _couponCode = code);
                                },
                              ),
                              const SizedBox(height: 24),

                              // Proceed button
                              SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  label: l10n.proceedToPayment,
                                  variant: AppButtonVariant.primary,
                                  onPressed: _selectedPlanId != null
                                      ? _handleProceed
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCards(AppLocalizations l10n, bool isNarrow) {
    final monthly = PlanCard(
      price: '\$30',
      period: l10n.perMonth,
      isSelected: _selectedPlanId == 2,
      onTap: () => setState(() => _selectedPlanId = 2),
    );

    final annual = Padding(
      padding: const EdgeInsets.only(top: 12),
      child: PlanCard(
        price: '\$300',
        period: l10n.perYear,
        isSelected: _selectedPlanId == 1,
        onTap: () => setState(() => _selectedPlanId = 1),
        badgeLabel: l10n.bestValue,
        savingsLabel: l10n.savePercent,
      ),
    );

    if (isNarrow) {
      return Column(
        children: [monthly, annual],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: monthly),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: PlanCard(
              price: '\$300',
              period: l10n.perYear,
              isSelected: _selectedPlanId == 1,
              onTap: () => setState(() => _selectedPlanId = 1),
              badgeLabel: l10n.bestValue,
              savingsLabel: l10n.savePercent,
            ),
          ),
        ),
      ],
    );
  }

  void _handleProceed() {
    // Step A3 will wire in the Tranzila popup here.
    // For now, just a placeholder.
  }
}
