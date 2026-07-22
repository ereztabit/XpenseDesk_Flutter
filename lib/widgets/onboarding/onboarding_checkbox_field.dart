import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Reusable labeled checkbox row for the onboarding wizard (e.g. the
/// marketing opt-in).
class OnboardingCheckboxField extends StatelessWidget {
  const OnboardingCheckboxField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    required this.labelStyle,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primaryDark,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: labelStyle),
          ),
        ],
      ),
    );
  }
}
