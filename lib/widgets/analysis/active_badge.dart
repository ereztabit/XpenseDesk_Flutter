import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class ActiveBadge extends StatelessWidget {
  final AppLocalizations l10n;

  const ActiveBadge({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        l10n.activeLabel,
        style: const TextStyle(
            color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
