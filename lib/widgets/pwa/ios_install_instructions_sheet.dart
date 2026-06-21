import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';

/// Bottom drawer explaining how to add XpenseDesk to the iOS home screen.
///
/// Linear, browser-agnostic flow: open Safari → go to the app URL → Share →
/// Add to Home Screen → Add. Starting with "Open Safari" covers users who
/// arrived in a non-Safari iOS browser (which can't add to the home screen).
class IosInstallInstructionsSheet extends StatelessWidget {
  const IosInstallInstructionsSheet({super.key});

  /// The production URL users navigate to in Safari.
  static const appUrl = 'https://app.xpensedesk.com';

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const IosInstallInstructionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.ios_share, size: 22, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.iosInstallSheetTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foreground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _StepRow(number: 1, text: l10n.iosInstallStepOpenSafari),
            const SizedBox(height: 14),
            _StepRow(
              number: 2,
              text: l10n.iosInstallStepGoTo,
              extra: const _UrlChip(url: appUrl),
            ),
            const SizedBox(height: 14),
            _StepRow(number: 3, text: l10n.iosInstallStepShare),
            const SizedBox(height: 14),
            _StepRow(number: 4, text: l10n.iosInstallStepAddToHome),
            const SizedBox(height: 14),
            _StepRow(number: 5, text: l10n.iosInstallStepAdd),
            const SizedBox(height: 24),
            AppButton(
              label: l10n.iosInstallSheetDone,
              variant: AppButtonVariant.primary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Numbered step row: a brand circle with the step number + the instruction,
/// plus an optional [extra] widget rendered beneath the text (e.g. the URL).
class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text, this.extra});

  final int number;
  final String text;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryForeground,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    color: AppTheme.foreground,
                  ),
                ),
              ),
              if (extra != null) ...[
                const SizedBox(height: 8),
                extra!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Selectable URL chip so the user can read (and copy) the address to type into
/// Safari. Forced LTR — a URL must never be reordered under RTL.
class _UrlChip extends StatelessWidget {
  const _UrlChip({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SelectableText(
          url,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryDark,
          ),
        ),
      ),
    );
  }
}
