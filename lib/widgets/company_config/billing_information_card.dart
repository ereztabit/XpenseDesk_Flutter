import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../models/company_billing.dart';
import '../../models/onboarding/reference_data.dart';
import '../../providers/billing_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../form_behavior_mixin.dart';
import '../app_button.dart';
import '../../utils/responsive_utils.dart';

/// Collapsible Billing Information card for the Billing tab (Story 4).
/// Pre-populated from billingInfo, saves via PUT /api/company/billing/info.
class BillingInformationCard extends ConsumerStatefulWidget {
  const BillingInformationCard({
    super.key,
    required this.billingInfo,
    required this.dirtyNotifier,
  });

  final BillingInfo billingInfo;

  /// The parent screen watches this to guard tab switches / back navigation.
  final ValueNotifier<bool> dirtyNotifier;

  @override
  ConsumerState<BillingInformationCard> createState() =>
      _BillingInformationCardState();
}

class _BillingInformationCardState
    extends ConsumerState<BillingInformationCard> {
  bool _expanded = false;
  bool _saving = false;
  bool _triedSubmit = false;
  String? _errorMessage;

  late final TextEditingController _nameController;
  late final TextEditingController _taxIdController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  String? _selectedCountryCode;

  // Snapshot of initial values for dirty checking
  late String _initialName;
  late String _initialTaxId;
  late String _initialAddress;
  late String _initialPhone;
  late String? _initialCountryCode;

  @override
  void initState() {
    super.initState();
    final info = widget.billingInfo;
    _nameController = TextEditingController(text: info.billingName ?? '');
    _taxIdController = TextEditingController(text: info.taxId ?? '');
    _addressController = TextEditingController(text: info.address ?? '');
    _phoneController = TextEditingController(text: info.phone ?? '');
    _selectedCountryCode = info.countryCode;

    _initialName = _nameController.text;
    _initialTaxId = _taxIdController.text;
    _initialAddress = _addressController.text;
    _initialPhone = _phoneController.text;
    _initialCountryCode = _selectedCountryCode;

    _nameController.addListener(_onFieldChanged);
    _taxIdController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    widget.dirtyNotifier.value = _isDirty;
  }

  bool get _isDirty =>
      _nameController.text != _initialName ||
      _taxIdController.text != _initialTaxId ||
      _addressController.text != _initialAddress ||
      _phoneController.text != _initialPhone ||
      _selectedCountryCode != _initialCountryCode;

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      _taxIdController.text.trim().isNotEmpty;

  String _summaryLine(AppLocalizations l10n) {
    final parts = <String>[];
    if (_nameController.text.trim().isNotEmpty) {
      parts.add(_nameController.text.trim());
    }
    if (widget.billingInfo.countryName != null &&
        widget.billingInfo.countryName!.isNotEmpty) {
      parts.add(widget.billingInfo.countryName!);
    }
    final taxId = _taxIdController.text.trim();
    if (taxId.isNotEmpty) {
      parts.add('${l10n.billingInfoTaxId}: $taxId');
    }
    return parts.join(', ');
  }

  Future<void> _handleSave() async {
    setState(() => _triedSubmit = true);

    if (!_canSave) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      await ref.read(billingProvider.notifier).saveBillingInfo(
            billingName: _nameController.text.trim(),
            taxId: _taxIdController.text.trim(),
            countryCode: _selectedCountryCode,
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          );

      // Update initial values so dirty check resets
      _initialName = _nameController.text;
      _initialTaxId = _taxIdController.text;
      _initialAddress = _addressController.text;
      _initialPhone = _phoneController.text;
      _initialCountryCode = _selectedCountryCode;
      widget.dirtyNotifier.value = false;
      _triedSubmit = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.billingInfoSaved),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = l10n.billingInfoFailedToSave);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _showError(TextEditingController controller) =>
      _triedSubmit && controller.text.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final refDataAsync = ref.watch(referenceDataProvider);
    final summary = _summaryLine(l10n);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Collapsible header ──────────────────────────────────
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.billingInformation,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!_expanded && summary.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              summary,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.mutedForeground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Expanded form ───────────────────────────────────────
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Billing Name + Tax ID (side-by-side on desktop, stacked on mobile)
                    if (context.isNarrow) ...[
                      _buildField(
                        label: l10n.billingInfoName,
                        controller: _nameController,
                        isRequired: true,
                        maxLength: 36,
                        hasError: _showError(_nameController),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        label: l10n.billingInfoTaxId,
                        controller: _taxIdController,
                        isRequired: true,
                        maxLength: 21,
                        hint: l10n.billingInfoTaxIdPlaceholder,
                        hasError: _showError(_taxIdController),
                      ),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildField(
                              label: l10n.billingInfoName,
                              controller: _nameController,
                              isRequired: true,
                              maxLength: 36,
                              hasError: _showError(_nameController),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: l10n.billingInfoTaxId,
                              controller: _taxIdController,
                              isRequired: true,
                              maxLength: 21,
                              hint: l10n.billingInfoTaxIdPlaceholder,
                              hasError: _showError(_taxIdController),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),

                    // Row 2: Country
                    FieldLabel(label: l10n.billingInfoCountry),
                    const SizedBox(height: 8),
                    refDataAsync.when(
                      loading: () => const SizedBox(
                        height: 48,
                        child: Center(
                            child:
                                CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (_, __) => Text(
                        '—',
                        style: TextStyle(color: AppTheme.mutedForeground),
                      ),
                      data: (refData) => _CountryDropdown(
                        countries: refData.countries,
                        selectedCode: _selectedCountryCode,
                        placeholder: l10n.billingInfoCountryPlaceholder,
                        onSelected: (code) {
                          setState(() => _selectedCountryCode = code);
                          widget.dirtyNotifier.value = _isDirty;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Row 3: Address
                    _buildField(
                      label: l10n.billingInfoAddress,
                      controller: _addressController,
                      hint: l10n.billingInfoAddressPlaceholder,
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),

                    // Row 4: Phone
                    _buildField(
                      label: l10n.billingInfoPhone,
                      controller: _phoneController,
                      maxLength: 20,
                    ),
                    const SizedBox(height: 24),

                    // Error
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.destructive.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppTheme.destructive, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppTheme.destructive,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Save button
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: AppButton(
                        label: l10n.saveChanges,
                        variant: AppButtonVariant.primary,
                        isLoading: _saving,
                        onPressed: _handleSave,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    String? hint,
    TextInputType? keyboardType,
    int? maxLength,
    bool hasError = false,
  }) {
    final borderColor = hasError ? AppTheme.destructive : AppTheme.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label, isRequired: isRequired),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? AppTheme.destructive : AppTheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Country dropdown ───────────────────────────────────────────────────────

class _CountryDropdown extends StatelessWidget {
  const _CountryDropdown({
    required this.countries,
    required this.selectedCode,
    required this.placeholder,
    required this.onSelected,
  });

  final List<OnboardingCountry> countries;
  final String? selectedCode;
  final String placeholder;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String?>(
      expandedInsets: EdgeInsets.zero,
      initialSelection: selectedCode,
      hintText: placeholder,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
      dropdownMenuEntries: countries
          .map((c) => DropdownMenuEntry<String?>(
                value: c.countryCode,
                label: c.countryName,
              ))
          .toList(),
      onSelected: onSelected,
    );
  }
}
