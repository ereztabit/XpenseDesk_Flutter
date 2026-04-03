import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company_billing.dart';
import 'auth_provider.dart';

final billingProvider = AsyncNotifierProvider<BillingNotifier, CompanyBilling>(
  BillingNotifier.new,
);

class BillingNotifier extends AsyncNotifier<CompanyBilling> {
  @override
  Future<CompanyBilling> build() async {
    final authService = ref.read(authServiceProvider);
    return authService.getBilling();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      return authService.getBilling();
    });
  }

  /// Upgrades from Monthly to Annual and patches state.
  Future<void> moveToAnnual() async {
    final authService = ref.read(authServiceProvider);
    final updated = await authService.moveToAnnual();
    _patchSubscription(updated);
  }

  /// Downgrades from Annual to Monthly and patches state.
  Future<void> moveToMonthly() async {
    final authService = ref.read(authServiceProvider);
    final updated = await authService.moveToMonthly();
    _patchSubscription(updated);
  }

  /// Resumes a cancelled subscription and patches state.
  Future<void> resumeSubscription() async {
    final authService = ref.read(authServiceProvider);
    final updated = await authService.resumeSubscription();
    _patchSubscription(updated);
  }

  /// Cancels the subscription and patches state.
  Future<void> cancelSubscription() async {
    final authService = ref.read(authServiceProvider);
    final updated = await authService.cancelSubscription();
    _patchSubscription(updated);
  }

  /// Saves billing information and refreshes billing state.
  Future<void> saveBillingInfo({
    required String billingName,
    required String taxId,
    String? countryCode,
    String? address,
    String? phone,
  }) async {
    final authService = ref.read(authServiceProvider);
    await authService.saveBillingInfo(
      billingName: billingName,
      taxId: taxId,
      countryCode: countryCode,
      address: address,
      phone: phone,
    );
    await refresh();
  }

  /// Cancels a scheduled future plan switch and patches state.
  Future<void> cancelFuturePlan() async {
    final authService = ref.read(authServiceProvider);
    final updated = await authService.cancelFuturePlan();
    _patchSubscription(updated);
  }

  /// Patches only the subscription in the current billing state.
  void _patchSubscription(BillingSubscription updated) {
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        CompanyBilling(
          subscription: updated,
          paymentMethod: current.paymentMethod,
          billingInfo: current.billingInfo,
        ),
      );
    }
  }
}
