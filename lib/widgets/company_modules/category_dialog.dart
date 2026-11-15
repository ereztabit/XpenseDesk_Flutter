import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/company_category.dart';
import '../../models/company_module.dart';
import '../../providers/company_modules_provider.dart';
import '../../services/company_modules_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/company_modules_utils.dart';
import '../app_button.dart';
import '../error_alert.dart';
import 'category_name_field.dart';
import 'tax_key_dropdown.dart';

/// Add / edit a category: Hebrew + English names (at least one), and a
/// required tax key on Travel. Saves through the API itself and shows the
/// server's error inline, so a duplicate name keeps the dialog open.
class CategoryDialog extends ConsumerStatefulWidget {
  const CategoryDialog({super.key, required this.module, this.editing});

  final CompanyModuleKey module;

  /// Null = add.
  final CompanyCategory? editing;

  /// True when the category was saved.
  static Future<bool> show(
    BuildContext context, {
    required CompanyModuleKey module,
    CompanyCategory? editing,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => CategoryDialog(module: module, editing: editing),
    );
    return saved ?? false;
  }

  @override
  ConsumerState<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<CategoryDialog> {
  late final TextEditingController _he;
  late final TextEditingController _en;
  TravelTaxKey? _taxKey;
  bool _saving = false;
  String? _error;

  bool get _isTravel => widget.module == CompanyModuleKey.travel;

  bool get _canSave =>
      !_saving &&
      (_he.text.trim().isNotEmpty || _en.text.trim().isNotEmpty) &&
      (!_isTravel || _taxKey != null);

  @override
  void initState() {
    super.initState();
    _he = TextEditingController(text: widget.editing?.nameHe ?? '')
      ..addListener(_changed);
    _en = TextEditingController(text: widget.editing?.nameEn ?? '')
      ..addListener(_changed);
    _taxKey = widget.editing?.taxKey;
  }

  void _changed() => setState(() => _error = null);

  @override
  void dispose() {
    _he.dispose();
    _en.dispose();
    super.dispose();
  }

  String? _clean(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _saving = true;
      _error = null;
    });
    final actions = ref.read(companyModulesActionsProvider);
    final taxKey = _isTravel ? _taxKey : null;
    try {
      final editing = widget.editing;
      if (editing == null) {
        await actions.addCategory(
          module: widget.module,
          nameEn: _clean(_en),
          nameHe: _clean(_he),
          taxKey: taxKey,
        );
      } else {
        await actions.updateCategory(
          editing.categoryId,
          nameEn: _clean(_en),
          nameHe: _clean(_he),
          taxKey: taxKey,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on CompanyModulesException catch (e) {
      if (mounted) {
        setState(() => _error = companyModulesErrorText(l10n, e.errorCode));
      }
    } catch (_) {
      if (mounted) setState(() => _error = l10n.modulesErrorGeneric);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        widget.editing == null ? l10n.categoriesAdd : l10n.categoriesEdit,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryNameField(
                label: l10n.categoriesNameHe,
                controller: _he,
                direction: TextDirection.rtl,
                enabled: !_saving,
              ),
              const SizedBox(height: 16),
              CategoryNameField(
                label: l10n.categoriesNameEn,
                controller: _en,
                direction: TextDirection.ltr,
                enabled: !_saving,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.categoriesNameHint,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.mutedForeground,
                ),
              ),
              if (_isTravel) ...[
                const SizedBox(height: 16),
                TaxKeyDropdown(
                  value: _taxKey,
                  enabled: !_saving,
                  onSelected: (v) => setState(() {
                    _taxKey = v;
                    _error = null;
                  }),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                ErrorAlert(message: _error!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        AppButton(
          label: l10n.cancel,
          variant: AppButtonVariant.ghost,
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: l10n.categoriesSave,
          isLoading: _saving,
          onPressed: _canSave ? _save : null,
        ),
      ],
    );
  }
}
