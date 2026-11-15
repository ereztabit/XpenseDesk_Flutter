import 'package:flutter/material.dart';

/// Labelled name input of the category dialog. [direction] is fixed per
/// language (Hebrew RTL, English LTR) whatever the UI language is.
class CategoryNameField extends StatelessWidget {
  const CategoryNameField({
    super.key,
    required this.label,
    required this.controller,
    required this.direction,
    required this.enabled,
  });

  final String label;
  final TextEditingController controller;
  final TextDirection direction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLength: 100,
          textDirection: direction,
          decoration: InputDecoration(
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
