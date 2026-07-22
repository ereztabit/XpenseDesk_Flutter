import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../app_button.dart';
import '../microsoft_logo.dart';

/// "or — Subscribe with Microsoft" block shown under the step 1 form
/// (feature-flagged). Tapping starts the MSAL redirect sign-in with
/// state = 'onboarding'.
class SubscribeWithMicrosoft extends StatelessWidget {
  const SubscribeWithMicrosoft({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.loginOrDivider,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: l10n.onboardingSubscribeWithMicrosoft,
            variant: AppButtonVariant.normal,
            iconWidget: const MicrosoftLogo(),
            isLoading: isLoading,
            onPressed: onPressed,
          ),
        ),
      ],
    );
  }
}
