import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/employee/employee_selector.dart';
import '../../widgets/category/category_selector.dart';

class AnalysisFilterCard extends StatelessWidget {
  final Map<String, String> availableEmployees;
  final Set<String> selectedEmployees;
  final Set<String> selectedCategories;
  final bool loading;
  final bool canRun;
  final AppLocalizations l10n;
  final ValueChanged<Set<String>> onEmployeesChanged;
  final ValueChanged<Set<String>> onCategoriesChanged;
  final VoidCallback onRun;

  const AnalysisFilterCard({
    super.key,
    required this.availableEmployees,
    required this.selectedEmployees,
    required this.selectedCategories,
    required this.loading,
    required this.canRun,
    required this.l10n,
    required this.onEmployeesChanged,
    required this.onCategoriesChanged,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            EmployeeSelector(
              employees: availableEmployees,
              selectedIds: selectedEmployees,
              enabled: !loading,
              sectionLabel: l10n.byEmployee,
              onChanged: onEmployeesChanged,
            ),
            const SizedBox(width: 16),
            CategorySelector(
              selectedCategoryAliases: selectedCategories,
              enabled: !loading,
              sectionLabel: l10n.byCategory,
              onChanged: onCategoriesChanged,
            ),
            const SizedBox(width: 16),
            FilledButton(
              onPressed: canRun ? onRun : null,
              child: Text(l10n.search),
            ),
          ],
        ),
      ),
    );
  }
}
