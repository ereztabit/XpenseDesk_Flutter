import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class TotalApprovedBadge extends StatelessWidget {
  const TotalApprovedBadge({
    super.key,
    required this.label,
    required this.amountText,
  });

  final String label;
  final String amountText;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.center,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.success.withAlpha(20),
          border: Border.all(color: AppTheme.success.withAlpha(70)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            '$label $amountText',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.success,
                ),
          ),
        ),
      ),
    );
  }
}
