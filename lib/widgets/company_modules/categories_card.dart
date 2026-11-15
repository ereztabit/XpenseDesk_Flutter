import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/company_category.dart';
import '../../models/company_module.dart';
import '../../providers/company_modules_provider.dart';
import '../../services/company_modules_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_utils.dart';
import '../../utils/company_modules_utils.dart';
import '../app_button.dart';
import '../bulk_upload/confirm_choice_dialog.dart';
import 'category_dialog.dart';
import 'category_row.dart';
import 'module_section_card.dart';

/// A module's categories editor: alphabetical list (inactive rows included),
/// Add, and per-row Edit / Delete / Reactivate. Delete is one action — the
/// server deletes an unused category and deactivates a used or system one.
class CategoriesCard extends ConsumerStatefulWidget {
  const CategoriesCard({super.key, required this.module});

  final CompanyModuleKey module;

  @override
  ConsumerState<CategoriesCard> createState() => _CategoriesCardState();
}

class _CategoriesCardState extends ConsumerState<CategoriesCard> {
  final Set<int> _busy = {};

  Future<void> _run(int id, Future<String?> Function() action) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy.add(id));
    try {
      final done = await action();
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } on CompanyModulesException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(companyModulesErrorText(l10n, e.errorCode))),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.modulesErrorGeneric)));
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _delete(CompanyCategory c) async {
    final l10n = AppLocalizations.of(context)!;
    final deactivates = c.isSystem || c.isUsed;
    final confirmed = await ConfirmChoiceDialog.show(
      context,
      title: c.isSystem
          ? l10n.categoriesSystemDeactivateTitle
          : l10n.categoriesDeleteTitle,
      body: c.isSystem
          ? l10n.categoriesSystemDeactivateBody
          : (c.isUsed
                ? l10n.categoriesDeactivateBody
                : l10n.categoriesDeleteBody),
      cancelLabel: l10n.cancel,
      confirmLabel: deactivates
          ? l10n.categoriesDeactivate
          : l10n.categoriesDelete,
      confirmVariant: AppButtonVariant.destructive,
    );
    if (!confirmed || !mounted) return;
    await _run(c.categoryId, () async {
      final outcome = await ref
          .read(companyModulesActionsProvider)
          .deleteCategory(c.categoryId);
      return outcome == CategoryDeleteOutcome.deleted
          ? l10n.categoriesDeleted
          : l10n.categoriesDeactivated;
    });
  }

  Future<void> _reactivate(CompanyCategory c) => _run(c.categoryId, () async {
    await ref
        .read(companyModulesActionsProvider)
        .reactivateCategory(c.categoryId);
    return null;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final categories = categoriesOfModule(
      ref.watch(companyCategoriesProvider),
      widget.module,
      lang,
    );

    return ModuleSectionCard(
      title: l10n.modulesCategories,
      padded: false,
      trailing: AppButton(
        label: l10n.categoriesAdd,
        variant: AppButtonVariant.normal,
        icon: Icons.add,
        dense: true,
        onPressed: () => CategoryDialog.show(context, module: widget.module),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in categories)
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: CategoryRow(
                category: c,
                lang: lang,
                busy: _busy.contains(c.categoryId),
                onEdit: () => CategoryDialog.show(
                  context,
                  module: widget.module,
                  editing: c,
                ),
                onDelete: () => _delete(c),
                onReactivate: () => _reactivate(c),
              ),
            ),
        ],
      ),
    );
  }
}
