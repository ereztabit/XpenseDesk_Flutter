import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/payments_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_navigator.dart';

/// Back arrow + title of the payments screen: "Payments & History" for a
/// manager, "History" for an employee (PC-9). Back pops, or - after a deep
/// link / refresh - goes to that user's dashboard. [trailing] fills the end.
class PaymentsTitleRow extends ConsumerWidget {
  const PaymentsTitleRow({super.key, this.compact = false, this.trailing = const []});

  /// Phone sizing: a smaller title that ellipsizes.
  final bool compact;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historyOnly = ref.watch(paymentsHistoryOnlyProvider);
    final title = Text(
      historyOnly ? l10n.historyTitle : l10n.paymentsHistoryTitle,
      style: TextStyle(
        fontSize: compact ? 20 : 22,
        fontWeight: FontWeight.w700,
        color: AppTheme.foreground,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.foreground),
          visualDensity: compact ? VisualDensity.compact : null,
          onPressed: () {
            final nav = Navigator.of(context);
            nav.canPop()
                ? nav.pop()
                : nav.pushReplacementNamed(historyOnly
                    ? AppRoutes.employeeDashboard
                    : AppRoutes.managerDashboard);
          },
        ),
        const SizedBox(width: 4),
        Expanded(child: title),
        ...trailing,
      ],
    );
  }
}
