import 'dart:ui';

import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_category.dart';
import '../../theme/app_theme.dart';

class CategorySelector extends StatelessWidget {
  final Set<String> selectedCategoryAliases;
  final ValueChanged<Set<String>> onChanged;
  final List<ExpenseCategory> categories;
  final double width;
  final bool enabled;
  final String? sectionLabel;

  const CategorySelector({
    super.key,
    required this.selectedCategoryAliases,
    required this.onChanged,
    this.categories = ExpenseCategory.orderedValues,
    this.width = 200,
    this.enabled = true,
    this.sectionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final isEnabled = enabled && categories.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (sectionLabel ?? l10n.byCategory).toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.mutedForeground,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: width,
          child: MenuAnchor(
            crossAxisUnconstrained: false,
            style: MenuStyle(
              minimumSize: WidgetStatePropertyAll(Size(width, 0)),
              maximumSize: WidgetStatePropertyAll(Size(width, 320)),
              backgroundColor: const WidgetStatePropertyAll(AppTheme.card),
              surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
            menuChildren: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: isEnabled
                          ? () => onChanged(
                              categories.map((category) => category.apiValue).toSet(),
                            )
                          : null,
                      child: Text(l10n.selectAll),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: isEnabled ? () => onChanged(<String>{}) : null,
                      child: Text(l10n.clear),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppTheme.border),
              ...categories.map(
                (category) => MenuItemButton(
                  closeOnActivate: false,
                  onPressed: isEnabled
                      ? () => onChanged(
                            _toggleAlias(
                              current: selectedCategoryAliases,
                              alias: category.apiValue,
                            ),
                          )
                      : null,
                  style: ButtonStyle(
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    foregroundColor:
                        const WidgetStatePropertyAll(AppTheme.foreground),
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(fontSize: 13),
                    ),
                  ),
                  leadingIcon: IgnorePointer(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: selectedCategoryAliases.contains(category.apiValue),
                        onChanged: null,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: AppTheme.borderMedium),
                      ),
                    ),
                  ),
                  child: Text(
                    category.labelForLocale(locale),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.foreground,
                    ),
                  ),
                ),
              ),
            ],
            builder: (context, controller, child) {
              return _CategoryTrigger(
                width: width,
                enabled: isEnabled,
                label: _summaryLabel(
                  l10n: l10n,
                  locale: locale,
                ),
                isOpen: controller.isOpen,
                onTap: () {
                  if (!isEnabled) return;
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _summaryLabel({
    required AppLocalizations l10n,
    required Locale locale,
  }) {
    if (selectedCategoryAliases.length == categories.length) {
      return l10n.allCategories;
    }

    if (selectedCategoryAliases.isEmpty) {
      return l10n.byCategory;
    }

    if (selectedCategoryAliases.length == 1) {
      final selected = categories.where(
        (category) => selectedCategoryAliases.contains(category.apiValue),
      );
      if (selected.isNotEmpty) {
        return selected.first.labelForLocale(locale);
      }
    }

    return '${selectedCategoryAliases.length} ${l10n.selectedLabel}';
  }

  Set<String> _toggleAlias({
    required Set<String> current,
    required String alias,
  }) {
    final next = Set<String>.from(current);
    if (next.contains(alias)) {
      next.remove(alias);
    } else {
      next.add(alias);
    }
    return next;
  }
}

class _CategoryTrigger extends StatelessWidget {
  final double width;
  final bool enabled;
  final String label;
  final bool isOpen;
  final VoidCallback onTap;

  const _CategoryTrigger({
    required this.width,
    required this.enabled,
    required this.label,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: enabled ? AppTheme.card : AppTheme.muted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isOpen ? AppTheme.primary : AppTheme.border,
            width: isOpen ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                12,
                isOpen ? 7 : 8,
                8,
                isOpen ? 7 : 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: enabled
                            ? AppTheme.foreground
                            : AppTheme.mutedForeground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppTheme.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
