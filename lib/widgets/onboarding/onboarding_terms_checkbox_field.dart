import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/menu_items.dart';
import '../../theme/app_theme.dart';

/// Terms & Privacy checkbox row for the onboarding wizard, with clickable
/// links for the Terms of Service and Privacy Policy.
class OnboardingTermsCheckboxField extends StatelessWidget {
  const OnboardingTermsCheckboxField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
            // Text.rich (not RichText) so the spans inherit the app's themed
            // font family — keeps this row's typography identical to the
            // plain-Text marketing checkbox below it.
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 13, color: AppTheme.foreground),
                children: [
                  TextSpan(text: l10n.onboardingTermsAcceptPrefix),
                  TextSpan(
                    text: l10n.termsOfService,
                    style: const TextStyle(
                      color: AppTheme.primaryDark,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.primaryDark,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = MenuItems.launchTerms,
                  ),
                  TextSpan(text: l10n.onboardingTermsAcceptMiddle),
                  TextSpan(
                    text: l10n.privacyPolicy,
                    style: const TextStyle(
                      color: AppTheme.primaryDark,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.primaryDark,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = MenuItems.launchPrivacy,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
