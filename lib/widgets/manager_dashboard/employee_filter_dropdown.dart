import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/manager_dashboard_provider.dart';
import '../../theme/app_theme.dart';

/// 160×32 dropdown that filters all three bucket cards atomically.
/// `null` value = "All employees" (sentinel-translated since `DropdownMenu`
/// works best with non-null generic types).
///
/// Source: `companyEmployeesProvider` — active employees only (RoleId=2,
/// Status=Active). Filtered + sorted alphabetically in the provider.
class EmployeeFilterDropdown extends ConsumerWidget {
  const EmployeeFilterDropdown({super.key});

  /// Non-null sentinel for the "All employees" option. Internally translated
  /// to `null` on the way to the provider.
  static const _allSentinel = '__ALL_EMPLOYEES__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.watch(selectedEmployeeFilterProvider);
    final employeesAsync = ref.watch(companyEmployeesProvider);

    final employees = employeesAsync.maybeWhen(
      data: (list) => list,
      orElse: () => const [],
    );

    final initialSelection = selected ?? _allSentinel;

    return DropdownMenu<String>(
      width: 160,
      initialSelection: initialSelection,
      enableSearch: false,
      leadingIcon: const Padding(
        padding: EdgeInsetsDirectional.only(start: 8),
        child: Icon(
          Icons.filter_list,
          size: 14,
          color: AppTheme.mutedForeground,
        ),
      ),
      textStyle: const TextStyle(fontSize: 12, color: AppTheme.foreground),
      inputDecorationTheme: InputDecorationTheme(
        isCollapsed: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        constraints: const BoxConstraints(minHeight: 36, maxHeight: 36),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
      dropdownMenuEntries: [
        DropdownMenuEntry<String>(
          value: _allSentinel,
          label: l10n.allEmployees,
        ),
        for (final emp in employees)
          DropdownMenuEntry<String>(
            value: emp.userId,
            label: emp.fullName.isEmpty ? emp.email : emp.fullName,
          ),
      ],
      onSelected: (value) {
        final newFilter = value == _allSentinel ? null : value;
        ref.read(selectedEmployeeFilterProvider.notifier).set(newFilter);
      },
    );
  }
}
