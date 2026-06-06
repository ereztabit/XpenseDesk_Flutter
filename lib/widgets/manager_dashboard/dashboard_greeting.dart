import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';

/// Time-of-day greeting + the manager's first name, e.g. "Good morning, Dana",
/// with the company name beneath it in small text for context.
///
/// The greeting word and the name are concatenated in the widget layer (no ARB
/// placeholders, per project convention). RTL is handled by the framework — in
/// Hebrew the comma and name flow right-to-left automatically.
class DashboardGreeting extends ConsumerWidget {
  const DashboardGreeting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userInfo = ref.watch(userInfoProvider);
    final firstName = _firstName(userInfo?.fullName ?? '');
    final greeting = _greetingFor(DateTime.now().hour, l10n);
    final companyName = userInfo?.companyName ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          firstName.isEmpty ? greeting : '$greeting, $firstName',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: context.isMobile ? 22 : 28,
              ),
        ),
        if (companyName.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            companyName,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }

  String _firstName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(' ').first;
  }

  String _greetingFor(int hour, AppLocalizations l10n) {
    if (hour < 12) return l10n.managerDashboardGreetingMorning;
    if (hour < 18) return l10n.managerDashboardGreetingAfternoon;
    return l10n.managerDashboardGreetingEvening;
  }
}
