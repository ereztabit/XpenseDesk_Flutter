import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../providers/admin_receipt_ai_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_utils.dart';
import '../../../utils/admin_format_utils.dart';
import '../../app_button.dart';
import '../../date_range_filter.dart';
import 'ai_company_dropdown.dart';
import 'ai_profile_dropdown.dart';

/// Usage filters: company, profile, expense date range, Clear. A change drops
/// the picked row - its scan list belonged to the old filters. Desktop: one
/// row across the whole card, the three 40px controls sharing the width evenly,
/// Clear at the end. Below 600px: stacked, every control and Clear full width.
class AiUsageFilters extends ConsumerWidget {
  const AiUsageFilters({super.key});

  static const double _stackBelow = 600;
  static const double _gap = 16;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filters = ref.watch(adminAiUsageFiltersProvider);
    final companies = ref.watch(adminAiCompaniesProvider).asData?.value ?? const [];
    final profiles = activeAiProfiles(ref.watch(adminAiProfilesProvider).asData?.value ?? const []);
    // Same caption as DateRangeFilter, so the three 40px controls line up.
    const label = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: AppTheme.mutedForeground,
    );

    void apply(AdminAiUsageFilters next) {
      ref.read(adminAiUsageFiltersProvider.notifier).set(next);
      ref.read(adminAiPickedRowProvider.notifier).set((picked: false, key: null));
    }

    Widget labelled(String caption, Widget control) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(caption.toUpperCase(), style: label),
        const SizedBox(height: 6),
        control,
      ],
    );

    List<Widget> controls(double width) => [
      labelled(
        l10n.adminAiFilterCompany,
        AiCompanyDropdown(
          companies: companies,
          selectedId: filters.companyId,
          allLabel: l10n.adminAiAllCompanies,
          width: width,
          onSelected: (id) => apply(filters.withCompany(id)),
        ),
      ),
      labelled(
        l10n.adminAiFilterProfile,
        AiProfileDropdown(
          profiles: profiles,
          selectedId: filters.profileId,
          allLabel: l10n.adminAiAllProfiles,
          width: width,
          onSelected: (id) => apply(filters.withProfile(id)),
        ),
      ),
      DateRangeFilter(
        sectionLabel: l10n.adminAiFilterDates,
        from: filters.from,
        to: filters.to,
        width: width,
        locale: kAdminFormatLocale,
        onChanged: (from, to) => apply(filters.withDates(from, to)),
      ),
    ];

    // Row: pinned to the inputs' 40px. Stacked: natural height - a fixed
    // 40px clipped the phone-size label.
    Widget clear({required bool inRow}) {
      final button = AppButton(
        label: l10n.adminAiClearFilters,
        variant: AppButtonVariant.normal,
        icon: Icons.filter_alt_off_outlined,
        onPressed: filters.isEmpty ? null : () => apply(AdminAiUsageFilters.none),
      );
      return inRow ? SizedBox(height: 40, child: button) : button;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.border),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth < _stackBelow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final control in controls(c.maxWidth)) ...[control, const SizedBox(height: 12)],
                clear(inRow: false),
              ],
            );
          }
          // The Clear button's room is measured off-line; the rest is shared.
          const clearWidth = 120.0;
          final width = (c.maxWidth - clearWidth - _gap * 3) / 3;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final control in controls(width)) ...[
                SizedBox(width: width, child: control),
                const SizedBox(width: _gap),
              ],
              SizedBox(width: clearWidth, child: clear(inRow: true)),
            ],
          );
        },
      ),
    );
  }
}
