import 'package:flutter/material.dart';

/// "Show deactivated" toggle, used by both admin lists (companies and people).
///
/// One widget rather than two because the behaviour is the same in both and so
/// is the hazard: the default must be OFF, and the label must be part of the tap
/// target — a lone 18px checkbox is a poor target, and this gets toggled on a
/// live support call.
class AdminShowInactiveCheckbox extends StatelessWidget {
  const AdminShowInactiveCheckbox({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: (next) => onChanged(next ?? false),
        ),
        Flexible(
          child: InkWell(
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
