import 'screen_imports.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _currencyCodeController = TextEditingController();
  final _merchantNameController = TextEditingController();
  final _noteController = TextEditingController();
  final _receiptRefController = TextEditingController();

  DateTime? _selectedExpenseDate;
  int? _selectedCategoryId;
  bool _isLoading = false;
  String? _errorMessage;
  String _initialCurrencyCode = '';

  @override
  void initState() {
    super.initState();
    final userInfo = ref.read(userInfoProvider);
    _initialCurrencyCode = userInfo?.currencyCode?.trim().toUpperCase() ?? '';
    _currencyCodeController.text = _initialCurrencyCode;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _currencyCodeController.dispose();
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
        _currencyCodeController.text.trim().toUpperCase() !=
            _initialCurrencyCode ||
        _merchantNameController.text.trim().isNotEmpty ||
        _noteController.text.trim().isNotEmpty ||
        _receiptRefController.text.trim().isNotEmpty;
  }

  String? _validateAmount(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;

    final parsed = double.tryParse(trimmed.replaceAll(',', ''));
    if (parsed == null || parsed <= 0) {
      return l10n.amountMustBePositive;
    }

    return null;
  }

  String? _validateCurrencyCode(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;

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

  Future<void> _selectExpenseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpenseDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
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
        currencyCode: _currencyCodeController.text.trim(),
        merchantName: _merchantNameController.text.trim(),
        note: _noteController.text.trim(),
        receiptRef: _receiptRefController.text.trim(),
      );

      ref.invalidate(expenseSearchProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.expenseCreatedSuccess)));

      Navigator.of(context).pushReplacementNamed('/user/dashboard');
    } on ExpenseException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = l10n.failedToCreateExpense);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                        amountController: _amountController,
                        currencyCodeController: _currencyCodeController,
                        merchantNameController: _merchantNameController,
                        noteController: _noteController,
                        receiptRefController: _receiptRefController,
                        isLoading: _isLoading,
                        onSelectExpenseDate: _selectExpenseDate,
                        onCategorySelected: (value) {
                          setState(() => _selectedCategoryId = value);
                        },
                        onSubmit: _handleSubmit,
                        amountValidator: _validateAmount,
                        currencyCodeValidator: _validateCurrencyCode,
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
