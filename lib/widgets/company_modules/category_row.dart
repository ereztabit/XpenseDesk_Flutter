import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/company_category.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_utils.dart';
import '../../utils/company_modules_utils.dart';
import '../action_icon_button.dart';

/// One category on a module page: single-line "current / other" name, tax-key
/// badge (Travel), lock for system / fallback rows, Inactive badge, then two
/// fixed icon slots — Edit, and Delete or Reactivate. A slot an action does not
/// apply to stays as an empty same-size box so the columns line up.
class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.category,
    required this.lang,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onReactivate,
  });

  final CompanyCategory category;
  final String lang;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReactivate;

  static const double _slot = 32;

  /// Unicode first-strong isolate: each name keeps its own direction inside
  /// the line, like HTML `<bdi>`.
  static final String _fsi = String.fromCharCode(0x2068);
  static final String _pdi = String.fromCharCode(0x2069);
  static String _isolate(String s) => '$_fsi$s$_pdi';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = category;
    final secondary = c.secondaryName(lang);
    final nameColor = c.isActive
        ? AppTheme.foreground
        : AppTheme.mutedForeground;
    final lockHint = c.isSystem
        ? l10n.categoriesSystemHint
        : (c.isFallback ? l10n.categoriesFallbackHint : null);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _isolate(c.displayName(lang)),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: nameColor,
                          ),
                        ),
                        if (secondary != null) ...[
                          const TextSpan(
                            text: ' / ',
                            style: TextStyle(color: AppTheme.mutedForeground),
                          ),
                          TextSpan(
                            text: _isolate(secondary),
                            style: TextStyle(color: nameColor),
                          ),
                        ],
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (c.taxKey != null) ...[
                  const SizedBox(width: 8),
                  _Badge(label: taxKeyLabel(l10n, c.taxKey!), outlined: true),
                ],
                if (lockHint != null) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: lockHint,
                    child: const Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
                if (!c.isActive) ...[
                  const SizedBox(width: 8),
                  _Badge(label: l10n.categoriesInactive, outlined: false),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (busy)
            const SizedBox(
              width: _slot * 2,
              height: _slot,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else ...[
            c.isSystem
                ? const SizedBox(width: _slot)
                : ActionIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: l10n.categoriesEditNames,
                    color: AppTheme.mutedForeground,
                    onPressed: onEdit,
                  ),
            if (!c.isActive)
              ActionIconButton(
                icon: Icons.restore,
                tooltip: l10n.categoriesReactivate,
                color: AppTheme.primary,
                onPressed: onReactivate,
              )
            else if (c.isFallback)
              const SizedBox(width: _slot)
            else
              ActionIconButton(
                icon: Icons.delete_outline,
                tooltip: l10n.categoriesDelete,
                color: AppTheme.destructive,
                onPressed: onDelete,
              ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.outlined});

  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: outlined ? null : AppTheme.muted,
        border: outlined ? Border.all(color: AppTheme.borderMedium) : null,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppTheme.mutedForeground),
      ),
    );
  }
}
