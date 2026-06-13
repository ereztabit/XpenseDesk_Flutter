import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';

/// Generic from→to date-range filter field: uppercase section label above a
/// 40px control with two tappable date slots (each opens a date picker) and a
/// clear affordance when a value is set. Dates display in the company locale.
///
/// Picking a "from" after the current "to" (or vice versa) clears the other
/// side so the range always stays valid.
class DateRangeFilter extends ConsumerWidget {
  const DateRangeFilter({
    super.key,
    required this.sectionLabel,
    required this.from,
    required this.to,
    required this.onChanged,
    this.width = 320,
  });

  final String sectionLabel;
  final DateTime? from;
  final DateTime? to;
  final void Function(DateTime? from, DateTime? to) onChanged;
  final double width;

  Future<void> _pick(BuildContext context, {required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? (from ?? to ?? now) : (to ?? from ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null) return;
    if (isFrom) {
      onChanged(picked, (to != null && picked.isAfter(to!)) ? null : to);
    } else {
      onChanged((from != null && picked.isBefore(from!)) ? null : from, picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);
    final hasValue = from != null || to != null;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sectionLabel.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today_outlined,
                    size: 15, color: AppTheme.mutedForeground),
                Expanded(
                  child: _DateSlot(
                    value: from,
                    hint: l10n.dateRangeFromHint,
                    locale: locale,
                    onTap: () => _pick(context, isFrom: true),
                  ),
                ),
                // En-dash separator — direction-neutral so the from→to range
                // doesn't read backwards under RTL (a directional arrow would).
                const Text('–',
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.mutedForeground)),
                Expanded(
                  child: _DateSlot(
                    value: to,
                    hint: l10n.dateRangeToHint,
                    locale: locale,
                    onTap: () => _pick(context, isFrom: false),
                  ),
                ),
                if (hasValue)
                  Tooltip(
                    message: l10n.clearDatesTooltip,
                    child: InkWell(
                      onTap: () => onChanged(null, null),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.close,
                            size: 14, color: AppTheme.mutedForeground),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One tappable date slot inside the range control (trivial styling helper).
class _DateSlot extends StatelessWidget {
  const _DateSlot({
    required this.value,
    required this.hint,
    required this.locale,
    required this.onTap,
  });

  final DateTime? value;
  final String hint;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value?.toCompanyDate(locale) ?? hint,
            style: TextStyle(
              fontSize: 13,
              color: value != null
                  ? AppTheme.foreground
                  : AppTheme.mutedForeground,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
