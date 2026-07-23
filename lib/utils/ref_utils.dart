import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart';

extension EntryRefresh on WidgetRef {
  /// Re-fetches [providers] when a screen is (re)entered.
  ///
  /// Call once from `didChangeDependencies` (guard with a `_didInvalidateOnEntry`
  /// flag). Riverpod 3.3 schedules an invalidation's rebuild on the root
  /// `ProviderScope` synchronously, so invalidating during the build phase
  /// throws `markNeedsBuild() called during build` — the invalidation must run
  /// after the current frame instead.
  ///
  /// A non-family provider that is not yet alive is skipped: the first build's
  /// `watch` already triggers its initial fetch, and a post-frame invalidate
  /// would fetch twice. Families cannot be liveness-checked, so they are always
  /// invalidated — their first-ever entry costs one redundant fetch.
  void invalidateOnEntry(List<ProviderOrFamily> providers) {
    final targets = providers
        .where((p) => p is! ProviderBase<Object?> || exists(p))
        .toList();
    if (targets.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      for (final provider in targets) {
        invalidate(provider);
      }
    });
  }
}
