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
