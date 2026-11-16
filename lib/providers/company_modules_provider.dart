import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/company_category.dart';
import '../models/company_module.dart';
import '../services/company_modules_service.dart';
import 'company_provider.dart';

final companyModulesServiceProvider = Provider<CompanyModulesService>((ref) {
  return CompanyModulesService();
});

/// FS-1010 modules, from GET /api/company. Empty while the company loads.
final companyModulesProvider = Provider<List<CompanyModule>>((ref) {
  return ref.watch(companyProvider).asData?.value.modules ?? const [];
});

/// FS-1010 categories of every module, inactive included.
final companyCategoriesProvider = Provider<List<CompanyCategory>>((ref) {
  return ref.watch(companyProvider).asData?.value.categories ?? const [];
});

/// Writes for the Modules tab. Each call patches [companyProvider] from the
/// returned item and rethrows [CompanyModulesException] for the UI to map.
final companyModulesActionsProvider = Provider<CompanyModulesActions>((ref) {
  return CompanyModulesActions(ref);
});

class CompanyModulesActions {
  CompanyModulesActions(this._ref);

  final Ref _ref;

  CompanyModulesService get _service =>
      _ref.read(companyModulesServiceProvider);
  CompanyNotifier get _company => _ref.read(companyProvider.notifier);

  /// FS-1011: a platform admin can hide a module while this page shows it. The
  /// server then refuses with `CompanyModuleNotAvailable`; reload the company
  /// so the stale module and its categories disappear, then rethrow for the UI
  /// to show the message.
  Future<T> _guard<T>(Future<T> Function() write) async {
    try {
      return await write();
    } on CompanyModulesException catch (e) {
      if (e.errorCode == 'CompanyModuleNotAvailable') await _company.refresh();
      rethrow;
    }
  }

  Future<void> setModuleEnabled(CompanyModuleKey module, bool isEnabled) =>
      _guard(() async => _company
          .applyModule(await _service.setModuleEnabled(module, isEnabled)));

  Future<void> setAllowNegativeBalance(bool allow) => _guard(() async =>
      _company.applyModule(await _service.setAllowNegativeBalance(allow)));

  Future<void> addCategory({
    required CompanyModuleKey module,
    String? nameEn,
    String? nameHe,
    TravelTaxKey? taxKey,
  }) =>
      _guard(() async => _company.applyCategory(
            await _service.addCategory(
              module: module,
              nameEn: nameEn,
              nameHe: nameHe,
              taxKey: taxKey,
            ),
          ));

  Future<void> updateCategory(
    int categoryId, {
    String? nameEn,
    String? nameHe,
    TravelTaxKey? taxKey,
  }) =>
      _guard(() async => _company.applyCategory(
            await _service.updateCategory(
              categoryId,
              nameEn: nameEn,
              nameHe: nameHe,
              taxKey: taxKey,
            ),
          ));

  Future<CategoryDeleteOutcome> deleteCategory(int categoryId) =>
      _guard(() async {
        final result = await _service.deleteCategory(categoryId);
        final category = result.category;
        if (result.outcome == CategoryDeleteOutcome.deleted) {
          _company.removeCategory(categoryId);
        } else if (category != null) {
          _company.applyCategory(category);
        } else {
          await _company.refresh();
        }
        return result.outcome;
      });

  Future<void> reactivateCategory(int categoryId) => _guard(() async =>
      _company.applyCategory(await _service.reactivateCategory(categoryId)));
}
