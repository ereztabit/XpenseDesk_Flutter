import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// One selectable entry in an [AppRadioGroup].
class AppRadioOption<T> {
  final T value;
  final String label;

  const AppRadioOption({required this.value, required this.label});
}

/// Vertical single-select radio group, themed to [AppTheme].
///
/// Each option is a full-width tappable row (radio circle + label), which
/// reads more clearly than loose chips for "pick exactly one" and avoids the
/// horizontal cramping a wide control would hit with long RTL labels.
class AppRadioGroup<T> extends StatelessWidget {
  const AppRadioGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<AppRadioOption<T>> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final option in options)
          _RadioRow(
            label: option.label,
            isSelected: option.value == selected,
            onTap: () => onSelected(option.value),
          ),
      ],
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _RadioCircle(isSelected: isSelected),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.foreground,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioCircle extends StatelessWidget {
  const _RadioCircle({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppTheme.primary : AppTheme.borderMedium,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                ),
              ),
            )
          : null,
    );
  }
}
