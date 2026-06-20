import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_version_provider.dart';
import '../../theme/app_theme.dart';

/// Muted app-version caption (`v1.0`) shown at the very bottom of the navigation
/// menus. Internal aid to verify a deployment has reached production. Renders
/// nothing until the version resolves.
class MenuVersionLabel extends ConsumerWidget {
  const MenuVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).asData?.value;
    if (version == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(
          version,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.mutedForeground,
          ),
        ),
      ),
    );
  }
}
