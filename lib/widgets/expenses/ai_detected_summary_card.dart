import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/receipt_analysis_result.dart';
import '../../theme/app_theme.dart';
import '../../utils/conversion_preview_controller.dart';
import '../../utils/format_utils.dart';
import 'conversion_preview_label.dart';

/// Read-only "Detected details" summary shown after an AI receipt scan.
///
/// The amount is formatted in the *detected* currency (which may be foreign)
/// using the company locale, so it reads like every other amount in the app.
class AiDetectedSummaryCard extends StatelessWidget {
  const AiDetectedSummaryCard({
    super.key,
    required this.result,
    required this.companyLocale,
    required this.conversion,
    required this.baseCurrency,
  });

  final ReceiptAnalysisResult? result;
  final String companyLocale;
  final ConversionPreviewController conversion;
  final String baseCurrency;

  String get _amountText {
    final amount = result?.amount;
    if (amount == null) return '—';
    final code = result?.currencyCode;
    if (code == null || code.isEmpty) {
      return amount.toFormattedNumber(companyLocale);
    }
    return amount.toCurrency(companyLocale, code);
  }

  String get _dateText {
    final isoDate = result?.expenseDate;
    if (isoDate == null) return '—';
    return DateTime.tryParse(isoDate)?.toCompanyDate(companyLocale) ?? isoDate;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _Cell(label: l10n.amountLabel, value: _amountText)),
            const SizedBox(width: 12),
            Expanded(child: _Cell(label: l10n.expenseDate, value: _dateText)),
          ],
        ),
        // Foreign-currency receipts: show the converted base value (or the
        // "no rate" error) for the detected currency + date.
        ConversionPreviewLabel(
          controller: conversion,
          companyLocale: companyLocale,
          baseCurrency: baseCurrency,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Cell(
                label: l10n.merchantLabel,
                value: result?.merchantName ?? '—',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.foreground,
          ),
        ),
      ],
    );
  }
}
