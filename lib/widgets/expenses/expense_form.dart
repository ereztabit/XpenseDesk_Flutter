import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_category.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../../utils/responsive_utils.dart';
import '../form_behavior_mixin.dart';

class ExpenseForm extends ConsumerWidget {
  const ExpenseForm({
    super.key,
    required this.formKey,
    required this.selectedExpenseDate,
    required this.selectedCategoryId,
    required this.amountController,
    required this.currencyCodeController,
    required this.merchantNameController,
    required this.noteController,
    required this.receiptRefController,
    required this.isLoading,
    required this.onSelectExpenseDate,
    required this.onCategorySelected,
    required this.onSubmit,
    required this.amountValidator,
    required this.currencyCodeValidator,
  });

  final GlobalKey<FormState> formKey;
  final DateTime? selectedExpenseDate;
  final int? selectedCategoryId;
  final TextEditingController amountController;
  final TextEditingController currencyCodeController;
  final TextEditingController merchantNameController;
  final TextEditingController noteController;
  final TextEditingController receiptRefController;
  final bool isLoading;
  final Future<void> Function() onSelectExpenseDate;
  final ValueChanged<int?> onCategorySelected;
  final VoidCallback onSubmit;
  final String? Function(String?) amountValidator;
  final String? Function(String?) currencyCodeValidator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final uiLocale = Localizations.localeOf(context);
    final companyLocale = ref.watch(companyLocaleProvider);
    final dateText = selectedExpenseDate?.toCompanyDate(companyLocale) ?? '';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 20 : 24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(label: l10n.expenseDate, isRequired: true),
              const SizedBox(height: 8),
              FormField<DateTime>(
                key: ValueKey(selectedExpenseDate),
                initialValue: selectedExpenseDate,
                validator: (value) =>
                    value == null ? l10n.expenseDateRequired : null,
                builder: (field) {
                  final borderColor = field.hasError
                      ? AppTheme.destructive
                      : AppTheme.border;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: isLoading ? null : onSelectExpenseDate,
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius,
                        ),
                        child: InputDecorator(
                          isEmpty: dateText.isEmpty,
                          decoration: InputDecoration(
                            errorText: null,
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                            ),
                            enabled: !isLoading,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                              borderSide: const BorderSide(
                                color: AppTheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            dateText.isEmpty ? l10n.selectDate : dateText,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: dateText.isEmpty
                                      ? AppTheme.mutedForeground
                                      : AppTheme.foreground,
                                ),
                          ),
                        ),
                      ),
                      if (field.hasError) ...[
                        const SizedBox(height: 6),
                        Text(
                          field.errorText!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.destructive),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              FieldLabel(label: l10n.categoryLabel, isRequired: true),
              const SizedBox(height: 8),
              FormField<int>(
                key: ValueKey(selectedCategoryId),
                initialValue: selectedCategoryId,
                validator: (value) =>
                    value == null ? l10n.categoryRequired : null,
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownMenu<int>(
                        key: ValueKey(selectedCategoryId),
                        initialSelection: selectedCategoryId,
                        enabled: !isLoading,
                        expandedInsets: EdgeInsets.zero,
                        hintText: l10n.selectCategory,
                        inputDecorationTheme: _dropdownTheme(field.hasError),
                        dropdownMenuEntries: ExpenseCategory.orderedValues
                            .map(
                              (category) => DropdownMenuEntry<int>(
                                value: category.id,
                                label: category.labelForLocale(uiLocale),
                              ),
                            )
                            .toList(),
                        onSelected: (value) {
                          field.didChange(value);
                          onCategorySelected(value);
                        },
                      ),
                      if (field.hasError) ...[
                        const SizedBox(height: 6),
                        Text(
                          field.errorText!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.destructive),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              FieldLabel(label: l10n.amountLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: amountController,
                enabled: !isLoading,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: amountValidator,
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 20),
              FieldLabel(label: l10n.currencyLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: currencyCodeController,
                enabled: !isLoading,
                textCapitalization: TextCapitalization.characters,
                maxLength: 3,
                validator: currencyCodeValidator,
                decoration: const InputDecoration(counterText: ''),
              ),
              const SizedBox(height: 20),
              FieldLabel(label: l10n.merchantLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: merchantNameController,
                enabled: !isLoading,
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 20),
              FieldLabel(label: l10n.receiptRefLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: receiptRefController,
                enabled: !isLoading,
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 20),
              FieldLabel(label: l10n.noteLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: noteController,
                enabled: !isLoading,
                maxLines: 4,
                minLines: 4,
                decoration: const InputDecoration(alignLabelWithHint: true),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: context.isMobile
                    ? Alignment.center
                    : Alignment.centerRight,
                child: SizedBox(
                  width: context.isMobile ? double.infinity : null,
                  child: FilledButton(
                    onPressed: isLoading ? null : onSubmit,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryForeground,
                              ),
                            ),
                          )
                        : Text(l10n.submitExpense),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecorationTheme _dropdownTheme(bool hasError) {
    final borderSide = BorderSide(
      color: hasError ? AppTheme.destructive : AppTheme.border,
      width: 1,
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        borderSide: borderSide,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        borderSide: borderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        borderSide: const BorderSide(color: AppTheme.destructive),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        borderSide: const BorderSide(color: AppTheme.destructive, width: 2),
      ),
      hintStyle: const TextStyle(color: AppTheme.mutedForeground),
    );
  }
}
