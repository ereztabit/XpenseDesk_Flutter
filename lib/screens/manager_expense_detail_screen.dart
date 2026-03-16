import 'package:flutter/services.dart';
import 'screen_imports.dart';
import '../models/expense_detail.dart';
import '../models/expense_category.dart';
import '../models/update_expense_request.dart';
import '../providers/expense_provider.dart';
import '../services/expense_service.dart';
import '../utils/format_utils.dart';
import '../utils/responsive_utils.dart';
import '../utils/expense_amount_input_formatter.dart';

class ManagerExpenseDetailScreen extends ConsumerStatefulWidget {
  final String expenseId;

  const ManagerExpenseDetailScreen({super.key, required this.expenseId});

  @override
  ConsumerState<ManagerExpenseDetailScreen> createState() =>
      _ManagerExpenseDetailScreenState();
}

class _ManagerExpenseDetailScreenState
    extends ConsumerState<ManagerExpenseDetailScreen>
    with FormBehaviorMixin {
  ExpenseDetail? _expense;
  bool _isLoading = true;
  bool _isNotFound = false;
  String? _loadError;

  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _selectedDate;
  int? _selectedCategoryId;

  bool _isSaving = false;
  String? _saveError;

  @override
  bool get hasUnsavedChanges => false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    _merchantController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExpense());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadExpense() async {
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final service = ref.read(expenseServiceProvider);
      final expense = await service.getExpenseById(widget.expenseId);
      _initForm(expense);
      if (mounted) setState(() { _expense = expense; _isLoading = false; });
    } on ExpenseNotFoundException {
      if (mounted) setState(() { _isNotFound = true; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _loadError = e.toString(); _isLoading = false; });
    }
  }

  void _initForm(ExpenseDetail expense) {
    _amountController.text = expense.amount != null
        ? expense.amount!.toStringAsFixed(expense.amount! % 1 == 0 ? 0 : 2)
        : '';
    _merchantController.text = expense.merchantName ?? '';
    _noteController.text = expense.note ?? '';
    _selectedDate = expense.expenseDate;
    _selectedCategoryId = expense.categoryId;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 180)),
      lastDate: now,
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _approve() async {
    if (_isSaving) return;
    setState(() { _isSaving = true; _saveError = null; });

    // Capture context-dependent values before any await.
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final service = ref.read(expenseServiceProvider);
      // Save any edits first, then approve.
      if (_expense != null) {
        await service.updateExpense(
          widget.expenseId,
          UpdateExpenseRequest(
            expenseDate: _selectedDate!.toIso8601String().split('T').first,
            categoryId: _selectedCategoryId!,
            merchantName: _merchantController.text.trim().isEmpty
                ? null : _merchantController.text.trim(),
            note: _noteController.text.trim().isEmpty
                ? null : _noteController.text.trim(),
            amount: double.tryParse(_amountController.text.replaceAll(',', '')),
          ),
        );
      }
      await service.approveExpense(widget.expenseId);
      if (!mounted) return;
      ref.invalidate(expenseSearchProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.expenseApproved)));
      navigator.pop();
    } on ExpenseNotFoundException {
      if (mounted) setState(() { _isSaving = false; _isNotFound = true; });
    } on ExpenseException catch (e) {
      if (mounted) setState(() { _isSaving = false; _saveError = e.message; });
    } catch (e) {
      if (mounted) setState(() { _isSaving = false; _saveError = e.toString(); });
    }
  }

  Future<void> _decline() async {
    if (_isSaving) return;
    setState(() { _isSaving = true; _saveError = null; });

    // Capture context-dependent values before any await.
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final service = ref.read(expenseServiceProvider);
      await service.declineExpense(widget.expenseId);
      if (!mounted) return;
      ref.invalidate(expenseSearchProvider);
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.expenseDeclined),
        backgroundColor: AppTheme.destructive,
      ));
      navigator.pop();
    } on ExpenseNotFoundException {
      if (mounted) setState(() { _isSaving = false; _isNotFound = true; });
    } on ExpenseException catch (e) {
      if (mounted) setState(() { _isSaving = false; _saveError = e.message; });
    } catch (e) {
      if (mounted) setState(() { _isSaving = false; _saveError = e.toString(); });
    }
  }

  // ── Build helpers ──────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppTheme.foreground,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool monospace = false,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          enabled: !_isSaving,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          style: TextStyle(fontFamily: monospace ? 'monospace' : null),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, String companyLocale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        InkWell(
          onTap: _isSaving ? null : _pickDate,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate?.toCompanyDate(companyLocale) ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppTheme.mutedForeground),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(AppLocalizations l10n, Locale uiLocale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(l10n.categoryLabel),
        DropdownMenu<int>(
          initialSelection: _selectedCategoryId,
          enabled: !_isSaving,
          expandedInsets: EdgeInsets.zero,
          hintText: l10n.selectCategory,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          dropdownMenuEntries: ExpenseCategory.orderedValues
              .map((cat) => DropdownMenuEntry<int>(
                    value: cat.id,
                    label: cat.labelForLocale(uiLocale),
                  ))
              .toList(),
          onSelected: _isSaving
              ? null
              : (value) => setState(() => _selectedCategoryId = value),
        ),
      ],
    );
  }

  Widget _buildAmountDateRow(String companyLocale, AppLocalizations l10n) {
    final amountField = _buildTextField(
      l10n.amountLabel,
      _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [ExpenseAmountInputFormatter()],
    );
    final dateField = _buildDateField(l10n.expenseDate, companyLocale);

    if (context.isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [amountField, const SizedBox(height: 12), dateField],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: amountField),
        const SizedBox(width: 12),
        Expanded(child: dateField),
      ],
    );
  }

  Widget _buildFormCard(AppLocalizations l10n, String companyLocale, Locale uiLocale) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _expense?.createdByName ?? '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildAmountDateRow(companyLocale, l10n),
            const SizedBox(height: 16),
            _buildTextField(l10n.merchantLabel, _merchantController),
            const SizedBox(height: 16),
            _buildCategoryDropdown(l10n, uiLocale),
            const SizedBox(height: 16),
            _buildTextField(l10n.noteLabel, _noteController, maxLines: 3),
            const SizedBox(height: 24),
            if (_saveError != null) ...[
              Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 16, color: AppTheme.destructive),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_saveError!,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.destructive)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            _buildActionButtons(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    final approveBtn = FilledButton.icon(
      onPressed: _isSaving ? null : _approve,
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.success,
        foregroundColor: Colors.white,
      ),
      icon: _isSaving
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.check, size: 16),
      label: Text(l10n.approve),
    );

    final declineBtn = FilledButton.icon(
      onPressed: _isSaving ? null : _decline,
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.destructive,
        foregroundColor: Colors.white,
      ),
      icon: const Icon(Icons.close, size: 16),
      label: Text(l10n.decline),
    );

    if (context.isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [approveBtn, const SizedBox(height: 8), declineBtn],
      );
    }
    return Row(
      children: [
        Expanded(child: approveBtn),
        const SizedBox(width: 12),
        Expanded(child: declineBtn),
      ],
    );
  }

  Widget _buildReceiptCard(AppLocalizations l10n) {
    final imageUrl = _expense?.imageUrl;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 20),
                const SizedBox(width: 8),
                Text(l10n.receipt,
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                if (imageUrl != null && imageUrl.isNotEmpty)
                  IconButton(
                    onPressed: () => _showExpandDialog(imageUrl),
                    icon: const Icon(Icons.open_in_full, size: 16),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(32, 32),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (imageUrl == null || imageUrl.isEmpty)
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.muted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.mutedForeground.withAlpha(77),
                        width: 2,
                        style: BorderStyle.solid),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload_outlined,
                            size: 32, color: AppTheme.mutedForeground),
                      ],
                    ),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => _showExpandDialog(imageUrl),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context2, err, stack) => Container(
                        color: AppTheme.muted,
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              size: 48, color: AppTheme.mutedForeground),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showExpandDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
              PositionedDirectional(
                top: 8,
                end: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.card.withAlpha(204),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.expenseNotFound,
              style: const TextStyle(
                  fontSize: 16, color: AppTheme.mutedForeground)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.backToDashboard),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_loadError ?? l10n.anErrorOccurred,
              style: const TextStyle(color: AppTheme.destructive)),
          const SizedBox(height: 16),
          OutlinedButton(
              onPressed: _loadExpense, child: Text(l10n.continueButton)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final companyLocale = ref.watch(companyLocaleProvider);
    final uiLocale = Localizations.localeOf(context);

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _isNotFound
                      ? _buildNotFound(l10n)
                      : _loadError != null
                          ? _buildError(l10n)
                          : SingleChildScrollView(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 24),
                              child: ConstrainedContent(
                                maxWidth: 960,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      icon: const Icon(Icons.arrow_back,
                                          size: 16),
                                      label: Text(l10n.backToDashboard),
                                    ),
                                    const SizedBox(height: 12),
                                    if (context.isDesktop)
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                              child: _buildReceiptCard(l10n)),
                                          const SizedBox(width: 24),
                                          Expanded(
                                              child: _buildFormCard(l10n,
                                                  companyLocale, uiLocale)),
                                        ],
                                      )
                                    else
                                      Column(
                                        children: [
                                          _buildReceiptCard(l10n),
                                          const SizedBox(height: 16),
                                          _buildFormCard(
                                              l10n, companyLocale, uiLocale),
                                        ],
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
