import 'dart:ui';

/// Local reference data for expense categories used by the MVP form.
///
/// These values are intentionally kept in-app rather than fetched from an API.
/// IDs and backend names match the current server seed data.
enum ExpenseCategory {
  travel(
    id: 1,
    apiValue: 'Travel',
    englishLabel: 'Travel',
    hebrewLabel: 'נסיעות',
  ),
  foodAndMeals(
    id: 2,
    apiValue: 'FoodNMeals',
    englishLabel: 'FoodNMeals',
    hebrewLabel: 'אוכל וארוחות',
  ),
  supplies(
    id: 3,
    apiValue: 'Supplies',
    englishLabel: 'Supplies',
    hebrewLabel: 'ציוד',
  ),
  software(
    id: 4,
    apiValue: 'Software',
    englishLabel: 'Software',
    hebrewLabel: 'תוכנה',
  ),
  other(
    id: 5,
    apiValue: 'Other',
    englishLabel: 'Other',
    hebrewLabel: 'אחר',
  ),
  hotels(
    id: 6,
    apiValue: 'Hotels',
    englishLabel: 'Hotels',
    hebrewLabel: 'מלונות',
  );

  const ExpenseCategory({
    required this.id,
    required this.apiValue,
    required this.englishLabel,
    required this.hebrewLabel,
  });

  final int id;
  final String apiValue;
  final String englishLabel;
  final String hebrewLabel;

  String labelForLocale(Locale locale) {
    return locale.languageCode == 'he' ? hebrewLabel : englishLabel;
  }

  static const List<ExpenseCategory> orderedValues = [
    travel,
    foodAndMeals,
    supplies,
    software,
    other,
    hotels,
  ];

  static ExpenseCategory? fromId(int? id) {
    if (id == null) return null;

    for (final category in orderedValues) {
      if (category.id == id) return category;
    }
    return null;
  }

  static ExpenseCategory? fromApiValue(String? apiValue) {
    if (apiValue == null || apiValue.isEmpty) return null;

    for (final category in orderedValues) {
      if (category.apiValue == apiValue) return category;
    }
    return null;
  }
}
