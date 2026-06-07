import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company_info.dart';
import '../models/tracked_currency.dart';
import 'auth_provider.dart';

/// Loads company details from GET /api/company.
/// Invalidate via `ref.invalidate(companyProvider)` to trigger a re-fetch.
final companyProvider = AsyncNotifierProvider<CompanyNotifier, CompanyInfo>(
  CompanyNotifier.new,
);

/// Server-driven currency list for the expense pickers (base entry first).
///
/// Sourced from `trackedCurrencies` on GET /api/company — watching this
/// triggers the company fetch and rebuilds when it lands. Falls back to a
/// single base-currency entry (from [companyBaseCurrencyProvider]) while the
/// company is still loading so the picker always has at least the base.
final trackedCurrenciesProvider = Provider<List<TrackedCurrency>>((ref) {
  final list = ref.watch(companyProvider).asData?.value.trackedCurrencies;
  if (list != null && list.isNotEmpty) return list;
  final base = ref.watch(companyBaseCurrencyProvider);
  return [
    TrackedCurrency(
      currencyCode: base,
      currencyName: base,
      currencySymbol: '',
      isBaseCurrency: true,
    ),
  ];
});

class CompanyNotifier extends AsyncNotifier<CompanyInfo> {
  @override
  Future<CompanyInfo> build() async {
    final authService = ref.read(authServiceProvider);
    return authService.getCompany();
  }

  /// Re-fetches company data from the API.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      return authService.getCompany();
    });
  }

  /// Updates company settings and refreshes state on success.
  Future<void> save({
    required String companyName,
    required int languageId,
    String? accountantEmail,
  }) async {
    final authService = ref.read(authServiceProvider);
    final updated = await authService.updateCompany(
      companyName: companyName,
      languageId: languageId,
      accountantEmail: accountantEmail,
    );
    state = AsyncData(updated);
  }
}
