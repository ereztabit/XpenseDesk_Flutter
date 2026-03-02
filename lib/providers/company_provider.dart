import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company_info.dart';
import '../services/auth_service.dart';
import 'auth_provider.dart';

/// Loads company details from GET /api/company.
/// Invalidate via `ref.invalidate(companyProvider)` to trigger a re-fetch.
final companyProvider = AsyncNotifierProvider<CompanyNotifier, CompanyInfo>(
  CompanyNotifier.new,
);

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
