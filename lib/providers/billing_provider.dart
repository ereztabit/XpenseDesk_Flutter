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

  /// Resumes a cancelled subscription and patches state.
  Future<void> resumeSubscription() async {
    final authService = ref.read(authServiceProvider);
    final updatedSubscription = await authService.resumeSubscription();
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        CompanyBilling(
          subscription: updatedSubscription,
          paymentMethod: current.paymentMethod,
          billingInfo: current.billingInfo,
        ),
      );
    }
  }

  /// Cancels the subscription and patches state with updated subscription.
  Future<void> cancelSubscription() async {
    final authService = ref.read(authServiceProvider);
    final updatedSubscription = await authService.cancelSubscription();
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        CompanyBilling(
          subscription: updatedSubscription,
          paymentMethod: current.paymentMethod,
          billingInfo: current.billingInfo,
        ),
      );
    }
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
    // Refresh to get updated billingInfo from server
    await refresh();
  }

  /// Calls DELETE /api/company/subscription/future-plan and patches state
  /// with the updated subscription returned by the server.
  Future<void> cancelFuturePlan() async {
    final authService = ref.read(authServiceProvider);
    final updatedSubscription = await authService.cancelFuturePlan();
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        CompanyBilling(
          subscription: updatedSubscription,
          paymentMethod: current.paymentMethod,
          billingInfo: current.billingInfo,
        ),
      );
    }
  }
}
