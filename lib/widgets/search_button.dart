import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';

/// A consistently-sized Search CTA button that matches the 40px trigger height
/// used by CycleSelector, EmployeeSelector, and CategorySelector.
class SearchButton extends StatelessWidget {
  const SearchButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 40,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: Text(l10n.search),
      ),
    );
  }
}
