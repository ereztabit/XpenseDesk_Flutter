import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

/// Labeled tappable date field used in the payment dialogs — opens a date
/// picker, displays the value in the company locale. Highlighted border to
/// signal the required field (mirrors the approved modal mock).
///
/// Defaults pick a past date (payments: last year up to today). The New budget
/// dialog passes a future range, starts empty ([value] null) and shows
/// [errorText].
class DialogDateField extends ConsumerWidget {
  const DialogDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;

  /// Null = one year ago / today.
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Inline red message under the field; null hides it.
  final String? errorText;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final first = firstDate ?? DateTime(now.year - 1);
    final last = lastDate ?? now;
    var initial = value ?? (now.isAfter(last) ? last : now);
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(companyLocaleProvider);
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
          ),
        ),
        InkWell(
          onTap: enabled ? () => _pick(context) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasError ? AppTheme.destructive : AppTheme.primary,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // LTR glyph order, but placed at the page's reading start
                // (right in Hebrew) - as the field was before FS-1012.
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      value?.toCompanyDate(locale) ?? '',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                          fontSize: 14, color: AppTheme.foreground),
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppTheme.mutedForeground),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, top: 6),
            child: Text(
              errorText!,
              style: const TextStyle(fontSize: 12, color: AppTheme.destructive),
            ),
          ),
      ],
    );
  }
}
