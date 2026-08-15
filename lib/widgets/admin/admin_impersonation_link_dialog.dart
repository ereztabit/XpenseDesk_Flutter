import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../services/impersonation_launcher.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';

/// Fallback shown when the browser blocked the connected tab outright.
///
/// The connect link is a bearer credential, so this dialog is the only place it
/// is ever displayed — and it exists because the alternative is worse: an agent
/// on a live call clicking Connect and nothing happening at all.
///
/// The link is not selectable text by default; Open and Copy are the two ways
/// out, both driven by a real tap so the blocker has nothing to refuse.
class AdminImpersonationLinkDialog extends StatelessWidget {
  const AdminImpersonationLinkDialog({
    super.key,
    required this.loginUrl,
    required this.targetUserName,
    this.launcher = const ImpersonationLauncher(),
  });

  final String loginUrl;
  final String targetUserName;
  final ImpersonationLauncher launcher;

  static Future<void> show(
    BuildContext context, {
    required String loginUrl,
    required String targetUserName,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AdminImpersonationLinkDialog(
        loginUrl: loginUrl,
        targetUserName: targetUserName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.adminImpersonateBlockedTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${l10n.impersonationBannerConnectedAs} $targetUserName'),
          const SizedBox(height: 12),
          Text(
            l10n.adminImpersonateBlockedBody,
            style: const TextStyle(color: AppTheme.mutedForeground),
          ),
        ],
      ),
      actions: [
        AppButton(
          label: l10n.adminImpersonateCopyLink,
          variant: AppButtonVariant.ghost,
          dense: true,
          onPressed: () async {
            await launcher.copyToClipboard(loginUrl);
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.adminImpersonateLinkCopied)),
              );
            }
          },
        ),
        AppButton(
          label: l10n.adminImpersonateOpenLink,
          variant: AppButtonVariant.primary,
          dense: true,
          onPressed: () {
            launcher.openNow(loginUrl);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
