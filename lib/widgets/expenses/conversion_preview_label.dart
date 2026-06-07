import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../services/expense_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/conversion_preview_controller.dart';
import '../../utils/format_utils.dart';

/// Read-only "converted amount" field shown beneath the currency picker.
///
/// Renders a captioned, bordered box (never an input) that mirrors
/// [ConversionPreviewController.status]: a spinner while converting, the
/// converted base-currency value on success, or a red error message on
/// failure (e.g. no published rate for the date — save stays blocked).
/// Renders nothing when idle (base currency / empty amount).
class ConversionPreviewLabel extends StatelessWidget {
  const ConversionPreviewLabel({
    super.key,
    required this.controller,
    required this.companyLocale,
    required this.baseCurrency,
  });

  final ConversionPreviewController controller;
  final String companyLocale;

  /// Company base currency code (e.g. "ILS"), used in the caption.
  final String baseCurrency;

  String _errorText(AppLocalizations l10n) {
    final error = controller.error;
    if (error is ExpenseException && error is! ExchangeRateUnavailableException) {
      return error.message;
    }
    return l10n.expenseExchangeRateUnavailable;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.status == ConversionStatus.idle) {
          return const SizedBox.shrink();
        }

        final isError = controller.status == ConversionStatus.error;

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.conversionPreviewAmountIn} $baseCurrency',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.foreground,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isError ? AppTheme.destructive : AppTheme.border,
                  ),
                ),
                child: _content(l10n),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _content(AppLocalizations l10n) {
    switch (controller.status) {
      case ConversionStatus.loading:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );

      case ConversionStatus.success:
        final preview = controller.preview!;
        return Text(
          preview.baseAmount.toCurrency(companyLocale, preview.baseCurrency),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        );

      case ConversionStatus.error:
        return Text(
          _errorText(l10n),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppTheme.destructive),
        );

      case ConversionStatus.idle:
        return const SizedBox.shrink();
    }
  }
}
