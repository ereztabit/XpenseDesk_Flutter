import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_category.dart';
import '../../models/expense_currency.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../../utils/expense_amount_input_formatter.dart';
import '../../utils/responsive_utils.dart';
import '../form_behavior_mixin.dart';

class ExpenseForm extends ConsumerWidget {
  static final RegExp _receiptRefInputPattern = RegExp(
    r'[a-zA-Z0-9\u0590-\u05FF /\\-]',
  );

  const ExpenseForm({
    super.key,
    required this.formKey,
    required this.selectedExpenseDate,
    required this.selectedCategoryId,
    required this.selectedCurrencyCode,
    required this.amountController,
    required this.merchantNameController,
    required this.noteController,
    required this.receiptRefController,
    required this.isLoading,
    required this.onSelectExpenseDate,
    required this.onCategorySelected,
    required this.onCurrencySelected,
    required this.onSubmit,
    required this.expenseDateValidator,
    required this.amountValidator,
    required this.currencyCodeValidator,
    required this.merchantNameValidator,
    required this.receiptRefValidator,
    required this.noteValidator,
  });

  final GlobalKey<FormState> formKey;
  final DateTime? selectedExpenseDate;
  final int? selectedCategoryId;
  final String? selectedCurrencyCode;
  final TextEditingController amountController;
  final TextEditingController merchantNameController;
  final TextEditingController noteController;
  final TextEditingController receiptRefController;
  final bool isLoading;
  final Future<void> Function() onSelectExpenseDate;
  final ValueChanged<int?> onCategorySelected;
  final ValueChanged<String?> onCurrencySelected;
  final VoidCallback onSubmit;
  final String? Function(DateTime?) expenseDateValidator;
  final String? Function(String?) amountValidator;
  final String? Function(String?) currencyCodeValidator;
  final String? Function(String?) merchantNameValidator;
  final String? Function(String?) receiptRefValidator;
  final String? Function(String?) noteValidator;

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
                validator: expenseDateValidator,
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
              FieldLabel(label: l10n.amountLabel, isRequired: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: amountController,
                enabled: !isLoading,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [ExpenseAmountInputFormatter()],
                validator: amountValidator,
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.amountRangeHelper,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: AppTheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 20),
              FieldLabel(label: l10n.currencyLabel, isRequired: true),
              const SizedBox(height: 8),
              FormField<String>(
                key: ValueKey(selectedCurrencyCode),
                initialValue: selectedCurrencyCode,
                validator: currencyCodeValidator,
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownMenu<String>(
                        key: ValueKey(selectedCurrencyCode),
                        initialSelection: selectedCurrencyCode,
                        enabled: !isLoading,
                        expandedInsets: EdgeInsets.zero,
                        hintText: l10n.currencyPlaceholder,
                        inputDecorationTheme: _dropdownTheme(field.hasError),
                        dropdownMenuEntries: ExpenseCurrency.values
                            .map(
                              (currency) => DropdownMenuEntry<String>(
                                value: currency.code,
                                label: currency.displayLabel,
                              ),
                            )
                            .toList(),
                        onSelected: (value) {
                          field.didChange(value);
                          onCurrencySelected(value);
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
              FieldLabel(label: l10n.merchantLabel, isRequired: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: merchantNameController,
                enabled: !isLoading,
                maxLength: 20,
                inputFormatters: [LengthLimitingTextInputFormatter(20)],
                validator: merchantNameValidator,
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 20),
              FieldLabel(label: l10n.receiptRefLabel, isRequired: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: receiptRefController,
                enabled: !isLoading,
                maxLength: 20,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(20),
                  FilteringTextInputFormatter.allow(_receiptRefInputPattern),
                ],
                validator: receiptRefValidator,
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 20),
              FieldLabel(label: l10n.noteLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: noteController,
                enabled: !isLoading,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                maxLines: 4,
                minLines: 4,
                maxLength: 100,
                validator: noteValidator,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
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
