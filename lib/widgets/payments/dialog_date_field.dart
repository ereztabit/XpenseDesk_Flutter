import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

/// Labeled tappable date field used in the payment dialogs — opens a date
/// picker, displays the value in the company locale. Highlighted border to
/// signal the required field (mirrors the approved modal mock).
class DialogDateField extends ConsumerWidget {
  const DialogDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(companyLocaleProvider);

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
              border: Border.all(color: AppTheme.primary, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.toCompanyDate(locale),
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.foreground),
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
}
