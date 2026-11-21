import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_scan_review.dart';
import '../../../services/json_viewer_service.dart';
import '../../../theme/app_theme.dart';
import '../../app_button.dart';
import 'ai_tab_strip.dart';
import '../../profile/profile_section_card.dart';

/// The model results as JSON: what Mistral read, what GPT read, and the whole
/// scan record - the same record the dev "View scan record" button opens.
class AiScanJsonCard extends StatefulWidget {
  const AiScanJsonCard({super.key, required this.review});

  final AdminAiScanReview review;

  @override
  State<AiScanJsonCard> createState() => _AiScanJsonCardState();
}

class _AiScanJsonCardState extends State<AiScanJsonCard> {
  int _tab = 2;

  Map<String, dynamic>? _json() {
    final r = widget.review;
    Map<String, dynamic>? model(AdminAiModelResult? m) => m == null
        ? null
        : {
            'step': m.step,
            'model': m.model,
            'durationMs': m.durationMs,
            if (m.reason != null) 'reason': m.reason,
            'result': m.values == null
                ? null
                : {
                    'merchant': m.values!.merchant,
                    'date': m.values!.date,
                    'amount': m.values!.amount,
                    'currency': m.values!.currency,
                    'tax_amount': m.values!.taxAmount,
                    'receipt_number': m.values!.receiptNumber,
                  },
          };
    return switch (_tab) {
      0 => model(r.mistral),
      1 => model(r.gpt),
      _ => r.scanRecord,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final json = _json();

    return ProfileSectionCard(
      icon: Icons.data_object,
      title: l10n.adminAiJsonTitle,
      children: [
        // Tabs at the start, the button at the end, centred on one line;
        // below 600px the button goes under the tabs, full width.
        LayoutBuilder(
          builder: (context, c) {
            final tabs = AiTabStrip(
              labels: [l10n.adminAiColMistral, l10n.adminAiColGpt, l10n.adminAiJsonFull],
              activeIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
            );
            final open = AppButton(
              label: l10n.adminAiOpenInNewTab,
              variant: AppButtonVariant.normal,
              icon: Icons.open_in_new,
              onPressed: json == null
                  ? null
                  : () => JsonViewerService.openInNewTab(json, 'scan-${widget.review.expenseId}.json'),
            );
            return c.maxWidth < 600
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [tabs, const SizedBox(height: 8), open],
                  )
                : Row(
                    children: [
                      Expanded(child: Align(alignment: AlignmentDirectional.centerStart, child: tabs)),
                      const SizedBox(width: 12),
                      open,
                    ],
                  );
          },
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 340),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.foreground, borderRadius: BorderRadius.circular(10)),
          child: SingleChildScrollView(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(
                json == null
                    ? (_tab == 1 ? l10n.adminAiNotCalled : l10n.adminAiNoRecord)
                    : const JsonEncoder.withIndent('  ').convert(json),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.6, color: AppTheme.muted),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
