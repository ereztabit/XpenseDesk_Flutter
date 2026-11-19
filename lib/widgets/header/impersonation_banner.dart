import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// "You are viewing someone else's account" marker (FS-1001), shown in the
/// **footer**: a banner pushed every screen down, and a chip in the header
/// crowded the bar and overflowed (owner QA 2026-11-19). The footer has room for
/// the full label at every width; the tooltip carries the whole sentence.
///
/// No dismiss control, by design. A marker you can close is a marker that is
/// closed.
///
/// Driven entirely by `userInfo.impersonatorName`, which the server sets. On an
/// ordinary session it is null and this renders nothing at all, so no existing
/// screen changes shape.
///
/// Ending the connection is the normal Disconnect in the header menu — there is
/// no separate exit here, because there is no separate mechanism.
class ImpersonationBanner extends ConsumerWidget {
  const ImpersonationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userInfo = ref.watch(userInfoProvider);

    if (userInfo == null || !userInfo.isImpersonated) {
      return const SizedBox.shrink();
    }

    final detail =
        '${l10n.impersonationBannerConnectedAs} '
        '${userInfo.fullName} · '
        '${l10n.impersonationBannerAgent} ${userInfo.impersonatorName}';

    return Tooltip(
      message: '${l10n.impersonationBannerLabel} — $detail',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.amber,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.support_agent,
              size: 16,
              color: AppTheme.foreground,
            ),
            const SizedBox(width: 6),
            Text(
              '${l10n.impersonationBannerLabel}: ${userInfo.fullName}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
