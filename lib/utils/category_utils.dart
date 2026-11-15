import '../models/company_category.dart';
import '../models/company_module.dart';
import '../models/expense_category.dart';

/// FS-1010 category display rules. [lang] is the UI language code ('he'/'en').
extension CompanyCategoryDisplay on CompanyCategory {
  /// The UI-language name, falling back to the other language's.
  String displayName(String lang) {
    final primary = lang == 'he' ? nameHe : nameEn;
    final other = lang == 'he' ? nameEn : nameHe;
    return primary ?? other ?? '';
  }

  /// The other language's name, or null when it is missing or already shown
  /// as the fallback display name.
  String? secondaryName(String lang) {
    final primary = lang == 'he' ? nameHe : nameEn;
    final other = lang == 'he' ? nameEn : nameHe;
    return primary == null ? null : other;
  }
}

/// [categories] of [module], sorted alphabetically by the display name.
List<CompanyCategory> categoriesOfModule(
  List<CompanyCategory> categories,
  CompanyModuleKey module,
  String lang,
) {
  final own = categories.where((c) => c.module == module).toList()
    ..sort(
      (a, b) => a
          .displayName(lang)
          .toLowerCase()
          .compareTo(b.displayName(lang).toLowerCase()),
    );
  return own;
}

/// The expense-form picker list: active Monthly categories, plus the
/// expense's current one ([keepCategoryId]) even if it was deactivated since.
List<CompanyCategory> expenseCategoryChoices(
  List<CompanyCategory> categories,
  String lang, {
  int? keepCategoryId,
}) {
  return categoriesOfModule(
    categories,
    CompanyModuleKey.monthly,
    lang,
  ).where((c) => c.isActive || c.categoryId == keepCategoryId).toList();
}

/// The name to show for an existing expense's category: the company's own
/// list first, then the legacy 1-6 table, then the server's [fallback] key.
String expenseCategoryLabel(
  List<CompanyCategory> categories,
  int categoryId,
  String lang, {
  String? fallback,
}) {
  for (final c in categories) {
    if (c.categoryId == categoryId) return c.displayName(lang);
  }
  final legacy = ExpenseCategory.fromId(categoryId);
  if (legacy != null) {
    return lang == 'he' ? legacy.hebrewLabel : legacy.englishLabel;
  }
  return fallback ?? '';
}

/// Maps a category id from the AI receipt scan (which may still be a legacy
/// 1-6 id) to one of the company's active Monthly categories. The default
/// copies keep the legacy Hebrew/English names, so a renamed one is missed —
/// null then, and the expense files under the fallback category.
int? resolveScannedCategoryId(
  List<CompanyCategory> categories,
  int? scannedId,
) {
  if (scannedId == null) return null;
  final active = categories
      .where((c) => c.module == CompanyModuleKey.monthly && c.isActive)
      .toList();
  if (active.any((c) => c.categoryId == scannedId)) return scannedId;
  final legacy = ExpenseCategory.fromId(scannedId);
  if (legacy == null) return null;
  for (final c in active) {
    if (c.nameHe == legacy.hebrewLabel || c.nameEn == legacy.englishLabel) {
      return c.categoryId;
    }
  }
  return null;
}

/// The Monthly fallback ("Other") — what an uncategorized expense files under.
int? fallbackCategoryId(List<CompanyCategory> categories) {
  for (final c in categories) {
    if (c.module == CompanyModuleKey.monthly && c.isFallback) {
      return c.categoryId;
    }
  }
  return null;
}
