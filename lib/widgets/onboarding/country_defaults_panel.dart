import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/onboarding/reference_data.dart';
import '../../theme/app_theme.dart';
import '../form_behavior_mixin.dart';

/// Shared [InputDecorationTheme] used by every [DropdownMenu] on the
/// onboarding company step so they look identical to the [TextFormField]s.
InputDecorationTheme onboardingDropdownInputTheme() => InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
    );

/// Shows the auto-filled Currency / Language / (Timezone) as a compact summary
/// line, with a collapsible section of editable dropdowns revealed by a
/// "Modify defaults" trigger.
///
/// [isExpanded] and [onToggleExpanded] are owned by the parent so that
/// selecting a new country can collapse the panel.
class CountryDefaultsPanel extends StatelessWidget {
  const CountryDefaultsPanel({
    super.key,
    required this.refData,
    required this.selectedCurrencyCode,
    required this.selectedLanguageId,
    required this.selectedTimeZoneId,
    required this.showTimeZone,
    required this.isExpanded,
    required this.hasDefaultsModified,
    required this.onToggleExpanded,
    required this.onCurrencyChanged,
    required this.onLanguageChanged,
    required this.onTimeZoneChanged,
  });

  final OnboardingReferenceData refData;
  final String? selectedCurrencyCode;
  final int? selectedLanguageId;
  final int? selectedTimeZoneId;
  final bool showTimeZone;
  final bool isExpanded;
  final bool hasDefaultsModified;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<int?> onLanguageChanged;
  final ValueChanged<int?> onTimeZoneChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final currency = refData.currencies
        .where((c) => c.currencyCode == selectedCurrencyCode)
        .firstOrNull;
    final language = refData.languages
        .where((lang) => lang.languageId == selectedLanguageId)
        .firstOrNull;
    final tz = refData.timeZones
        .where((t) => t.timeZoneId == selectedTimeZoneId)
        .firstOrNull;

    final summaryParts = <String>[
      if (currency != null)
        '${currency.currencySymbol} ${currency.currencyName}',
      if (language != null) language.languageName,
      if (showTimeZone && tz != null) tz.displayName,
    ];
    final summaryText = summaryParts.join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.primaryDark.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Summary line ─────────────────────────────────────────────────
          Text(
            summaryText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 8),

          // ── Modify / Hide trigger ─────────────────────────────────────────
          GestureDetector(
            onTap: onToggleExpanded,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: AppTheme.primaryDark,
                ),
                const SizedBox(width: 4),
                Text(
                  isExpanded
                      ? l10n.onboardingHideDefaults
                      : l10n.onboardingModifyDefaults,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(width: 2),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
          ),

          // ── Collapsible dropdowns ─────────────────────────────────────────
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              heightFactor: isExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Currency
                    FieldLabel(label: l10n.onboardingCurrency),
                    const SizedBox(height: 6),
                    DropdownMenu<String>(
                      // MVP: only ILS is supported end to end, so the base
                      // currency is fixed to the country default and cannot be
                      // changed. Re-enable when multi-currency ships
                      // (docs/backlog/multi-currency-expenses.md).
                      enabled: false,
                      key: ValueKey(selectedCurrencyCode),
                      initialSelection: selectedCurrencyCode,
                      expandedInsets: EdgeInsets.zero,
                      inputDecorationTheme: onboardingDropdownInputTheme(),
                      dropdownMenuEntries: refData.currencies
                          .map(
                            (c) => DropdownMenuEntry(
                              value: c.currencyCode,
                              label: '${c.currencySymbol}  ${c.currencyName}',
                            ),
                          )
                          .toList(),
                      onSelected: onCurrencyChanged,
                    ),
                    const SizedBox(height: 12),

                    // Language
                    FieldLabel(label: l10n.language),
                    const SizedBox(height: 6),
                    DropdownMenu<int>(
                      key: ValueKey(selectedLanguageId),
                      initialSelection: selectedLanguageId,
                      expandedInsets: EdgeInsets.zero,
                      inputDecorationTheme: onboardingDropdownInputTheme(),
                      dropdownMenuEntries: refData.languages
                          .map(
                            (lang) => DropdownMenuEntry(
                              value: lang.languageId,
                              label: lang.languageName,
                            ),
                          )
                          .toList(),
                      onSelected: onLanguageChanged,
                    ),

                    // Timezone — only for multi-timezone countries
                    if (showTimeZone) ...[
                      const SizedBox(height: 12),
                      FieldLabel(label: l10n.onboardingTimezone),
                      const SizedBox(height: 6),
                      DropdownMenu<int>(
                        key: ValueKey(selectedTimeZoneId),
                        initialSelection: selectedTimeZoneId,
                        expandedInsets: EdgeInsets.zero,
                        inputDecorationTheme: onboardingDropdownInputTheme(),
                        dropdownMenuEntries: refData.timeZones
                            .map(
                              (tz) => DropdownMenuEntry(
                                value: tz.timeZoneId,
                                label: tz.displayName,
                              ),
                            )
                            .toList(),
                        onSelected: onTimeZoneChanged,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Amber warning when defaults have been overridden ──────────────
          if (hasDefaultsModified) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.amber.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(
                  color: AppTheme.amber.withValues(alpha: 0.50),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppTheme.amber,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.onboardingDefaultsModified,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
