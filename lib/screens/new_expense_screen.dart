import 'screen_imports.dart';
import '../models/expense_currency.dart';
import '../providers/expense_provider.dart';
import '../services/expense_service.dart';
import '../widgets/expenses/expense_form.dart';

class NewExpenseScreen extends ConsumerStatefulWidget {
  const NewExpenseScreen({super.key});

  @override
  ConsumerState<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends ConsumerState<NewExpenseScreen>
    with FormBehaviorMixin {
  static final RegExp _receiptRefPattern = RegExp(
    r'^[a-zA-Z0-9\u0590-\u05FF /\\-]+$',
  );

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantNameController = TextEditingController();
  final _noteController = TextEditingController();
  final _receiptRefController = TextEditingController();

  DateTime? _selectedExpenseDate;
  int? _selectedCategoryId;
  String? _selectedCurrencyCode;
  bool _isLoading = false;
  String? _errorMessage;
  String? _initialCurrencyCode;

  DateTime get _latestExpenseDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _earliestExpenseDate {
    final latest = _latestExpenseDate;
    return DateTime(latest.year, latest.month - 6, latest.day);
  }

  @override
  void initState() {
    super.initState();
    final userInfo = ref.read(userInfoProvider);
    final defaultCurrency = ExpenseCurrency.fromCode(userInfo?.currencyCode);
    _initialCurrencyCode = defaultCurrency?.code;
    _selectedCurrencyCode = defaultCurrency?.code;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantNameController.dispose();
    _noteController.dispose();
    _receiptRefController.dispose();
    super.dispose();
  }

  @override
  bool get hasUnsavedChanges {
    return _selectedExpenseDate != null ||
        _selectedCategoryId != null ||
        _amountController.text.trim().isNotEmpty ||
        _selectedCurrencyCode != _initialCurrencyCode ||
        _merchantNameController.text.trim().isNotEmpty ||
        _noteController.text.trim().isNotEmpty ||
        _receiptRefController.text.trim().isNotEmpty;
  }

  String? _validateExpenseDate(DateTime? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null) {
      return l10n.expenseDateRequired;
    }

    final normalizedValue = DateTime(value.year, value.month, value.day);
    if (normalizedValue.isAfter(_latestExpenseDate)) {
      return l10n.expenseDateFutureNotAllowed;
    }

    if (normalizedValue.isBefore(_earliestExpenseDate)) {
      return l10n.expenseDateOlderThanSixMonths;
    }

    return null;
  }

  String? _validateAmount(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n.amountRequired;
    }

    final parsed = double.tryParse(trimmed.replaceAll(',', ''));
    if (parsed == null || parsed < 1) {
      return l10n.amountMustBePositive;
    }

    if (parsed > 10000) {
      return l10n.amountMaxValue;
    }

    return null;
  }

  String? _validateCurrencyCode(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n.currencyRequired;
    }

    if (!RegExp(r'^[a-zA-Z]{3}$').hasMatch(trimmed)) {
      return l10n.currencyCodeInvalid;
    }

    return null;
  }

  double? _parseAmount() {
    final trimmed = _amountController.text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll(',', ''));
  }

  String? _validateMerchantName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n.merchantRequired;
    }
    if (trimmed.length > 20) {
      return l10n.merchantMaxLength;
    }
    return null;
  }

  String? _validateReceiptRef(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n.receiptRefRequired;
    }
    if (trimmed.length > 20) {
      return l10n.receiptRefMaxLength;
    }
    if (!_receiptRefPattern.hasMatch(trimmed)) {
      return l10n.receiptRefInvalidCharacters;
    }
    return null;
  }

  String? _validateNote(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value != null && value.length > 100) {
      return l10n.notesMaxLength;
    }
    return null;
  }

  Future<void> _selectExpenseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpenseDate ?? _latestExpenseDate,
      firstDate: _earliestExpenseDate,
      lastDate: _latestExpenseDate,
    );

    if (picked != null && mounted) {
      setState(() => _selectedExpenseDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final expenseDate = _selectedExpenseDate;
    final categoryId = _selectedCategoryId;
    if (expenseDate == null || categoryId == null) {
      return;
    }

    setState(() => _isLoading = true);

    final l10n = AppLocalizations.of(context)!;
    final expenseService = ref.read(expenseServiceProvider);

    try {
      await expenseService.createExpense(
        expenseDate: expenseDate,
        categoryId: categoryId,
        amount: _parseAmount(),
        currencyCode: _selectedCurrencyCode,
        merchantName: _merchantNameController.text.trim(),
        note: _noteController.text.trim(),
        receiptRef: _receiptRefController.text.trim(),
      );
    } on ExpenseException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.failedToCreateExpense;
      });
      return;
    }

    if (!mounted) return;

    ref.invalidate(expenseSearchProvider);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.expenseCreatedSuccess)));

    setState(() => _isLoading = false);
    Navigator.of(context).pushReplacementNamed('/user/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ConstrainedContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            handleBackNavigation('/user/dashboard'),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: Text(l10n.backToDashboard),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.newExpense,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null) ...[
                        ErrorAlert(message: _errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      ExpenseForm(
                        formKey: _formKey,
                        selectedExpenseDate: _selectedExpenseDate,
                        selectedCategoryId: _selectedCategoryId,
                        selectedCurrencyCode: _selectedCurrencyCode,
                        amountController: _amountController,
                        merchantNameController: _merchantNameController,
                        noteController: _noteController,
                        receiptRefController: _receiptRefController,
                        isLoading: _isLoading,
                        onSelectExpenseDate: _selectExpenseDate,
                        onCategorySelected: (value) {
                          setState(() => _selectedCategoryId = value);
                        },
                        onCurrencySelected: (value) {
                          setState(() => _selectedCurrencyCode = value);
                        },
                        onSubmit: _handleSubmit,
                        expenseDateValidator: _validateExpenseDate,
                        amountValidator: _validateAmount,
                        currencyCodeValidator: _validateCurrencyCode,
                        merchantNameValidator: _validateMerchantName,
                        receiptRefValidator: _validateReceiptRef,
                        noteValidator: _validateNote,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}
