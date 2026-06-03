import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/responsive_utils.dart';
import '../providers/expense_provider.dart';
import '../providers/expense_sheet_provider.dart';
import '../providers/manager_dashboard_provider.dart';
import '../providers/users_provider.dart';
import '../providers/company_provider.dart';

/// Invalidates all major data providers. Call this from any pull-to-refresh
/// handler to refresh the current screen's server-backed data.
///
/// Only providers that are currently being watched will trigger a re-fetch;
/// inactive providers are silently reset.
Future<void> refreshAllProviders(WidgetRef ref) async {
  // Generic data providers
  ref.invalidate(expenseSearchProvider);
  ref.invalidate(cyclesProvider);
  ref.invalidate(usersListProvider);
  ref.invalidate(companyProvider);

  // Sheet providers (employee dashboard)
  ref.invalidate(mySheetsProvider);
  ref.invalidate(sheetDetailProvider);

  // Manager dashboard providers — invalidating the family wipes every
  // currently-cached `userId` filter combination.
  ref.invalidate(companyEmployeesProvider);
  ref.invalidate(approvalsQueueProvider);
  ref.invalidate(returnedSheetsProvider);
  ref.invalidate(approvedSheetsProvider);

  // Brief pause so the indicator is visible before content loading takes over.
  await Future.delayed(const Duration(milliseconds: 400));
}

/// Drop-in replacement for [SingleChildScrollView] in the mandatory scaffold
/// pattern. On mobile it wraps the content in a [RefreshIndicator] that
/// invalidates all data providers — no per-screen wiring needed.
///
/// On desktop the widget behaves identically to a plain [SingleChildScrollView].
///
/// Usage — replace [SingleChildScrollView] in every screen scaffold body:
/// ```dart
/// RefreshableScrollView(
///   padding: const EdgeInsets.symmetric(vertical: 24),
///   child: ConstrainedContent(...),
/// )
/// ```
class RefreshableScrollView extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const RefreshableScrollView({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = context.isMobile;

    final scrollView = SingleChildScrollView(
      physics: isMobile ? const AlwaysScrollableScrollPhysics() : null,
      padding: padding,
      child: child,
    );

    if (isMobile) {
      return RefreshIndicator(
        onRefresh: () => refreshAllProviders(ref),
        child: scrollView,
      );
    }

    return scrollView;
  }
}
