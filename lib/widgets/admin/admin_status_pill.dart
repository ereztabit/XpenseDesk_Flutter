import 'package:flutter/material.dart';

/// A small coloured status pill for admin tables (FS-1019). Same look as
/// [AdminCompanyStatusBadge], but takes the label and colour directly, so any
/// admin module can paint its own statuses without a new badge widget.
class AdminStatusPill extends StatelessWidget {
  const AdminStatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withAlpha(102)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
