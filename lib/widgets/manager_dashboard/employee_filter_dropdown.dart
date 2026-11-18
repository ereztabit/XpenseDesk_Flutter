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
///
/// The budget list (FS-1012) passes its own [options] (the budget holders),
/// [value] and [onSelected] instead of the shared provider.
class EmployeeFilterDropdown extends ConsumerWidget {
  const EmployeeFilterDropdown({super.key, this.options, this.value, this.onSelected, this.width = 160});

  /// userId → display name, already sorted. Null = the company's employees.
  final List<({String userId, String name})>? options;

  /// Selected userId (null = All employees) when [options] is set.
  final String? value;
  final ValueChanged<String?>? onSelected;

  /// 160 on Sheet Approvals; the budget list passes more so "All employees"
  /// is not clipped.
  final double width;

  /// Non-null sentinel for the "All employees" option. Internally translated
  /// to `null` on the way to the provider.
  static const _allSentinel = '__ALL_EMPLOYEES__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final custom = options != null;
    final selected = custom ? value : ref.watch(selectedEmployeeFilterProvider);
    final employees = custom
        ? options!
        : [
            for (final emp in ref.watch(companyEmployeesProvider).asData?.value ?? const [])
              (userId: emp.userId, name: emp.fullName.isEmpty ? emp.email : emp.fullName),
          ];

    final initialSelection = selected ?? _allSentinel;

    return DropdownMenu<String>(
      // DropdownMenu writes the selected label into its field once; keying it
      // by locale rebuilds that text when the language changes (FS-1013 QA:
      // "All employees" stayed English on a Hebrew screen).
      key: ValueKey(Localizations.localeOf(context).languageCode),
      width: width,
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
            label: emp.name,
          ),
      ],
      onSelected: (picked) {
        final newFilter = picked == _allSentinel ? null : picked;
        if (custom) {
          onSelected?.call(newFilter);
        } else {
          ref.read(selectedEmployeeFilterProvider.notifier).set(newFilter);
        }
      },
    );
  }
}
