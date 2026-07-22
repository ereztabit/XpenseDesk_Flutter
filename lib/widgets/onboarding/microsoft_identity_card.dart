import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../microsoft_logo.dart';

/// Verified-identity card shown on onboarding step 1 in Microsoft mode:
/// avatar with initial, full name, locked email, a "Signed in with Microsoft"
/// badge, and a "Use a different account" link that restarts the flow.
class MicrosoftIdentityCard extends StatelessWidget {
  const MicrosoftIdentityCard({
    super.key,
    required this.fullName,
    required this.email,
    required this.onUseDifferentAccount,
  });

  final String fullName;
  final String email;
  final VoidCallback onUseDifferentAccount;

  String get _initial {
    final source = fullName.trim().isNotEmpty ? fullName.trim() : email.trim();
    return source.isNotEmpty ? source.substring(0, 1).toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.muted,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryDark,
            child: Text(
              _initial,
              style: const TextStyle(
                color: AppTheme.primaryForeground,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                ),
                Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const MicrosoftLogo(size: 12),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        l10n.onboardingSignedInWithMicrosoft,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.check_circle,
                      size: 13,
                      color: AppTheme.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onUseDifferentAccount,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.onboardingUseDifferentAccount,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
