import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/admin_company_user_row.dart';
import '../../providers/admin_provider.dart';
import '../../services/impersonation_launcher.dart';
import '../../theme/app_theme.dart';
import '../sticky_report_table.dart';
import 'admin_company_user_table_row.dart';
import 'admin_company_users_table_header.dart';
import 'admin_impersonation_link_dialog.dart';

/// The company's people, with the Connect action (FS-1001 module #2).
///
/// Built on the shared [StickyReportTable] shell, same as the companies table:
/// sticky header, dual scroll with visible scrollbars, selectable body text, and
/// the standard loading/error states. Not sortable — the server's order
/// (managers first, then employees, each by name) is the feature.
///
/// This widget owns the connect orchestration because a row must stay stateless
/// (see [AdminCompanyUserTableRow]).
class AdminCompanyUsersTable extends ConsumerStatefulWidget {
  const AdminCompanyUsersTable({
    super.key,
    required this.companyId,
    required this.users,
    required this.isLoading,
    required this.hasError,
    required this.companyHasAnyPeople,
    required this.isSearching,
    this.launcher = const ImpersonationLauncher(),
  });

  final String companyId;

  /// Already filtered and already confirmed to belong to [companyId] by
  /// [AdminCompanyUsersBody] — this widget never second-guesses that.
  final List<AdminCompanyUserRow> users;

  final bool isLoading;
  final bool hasError;

  /// Whether this company has people at all, ignoring the deactivated filter.
  final bool companyHasAnyPeople;

  /// A search query is active, so an empty result is "no matches", not "no
  /// people". Three different facts, three different messages.
  final bool isSearching;

  final ImpersonationLauncher launcher;

  @override
  ConsumerState<AdminCompanyUsersTable> createState() =>
      _AdminCompanyUsersTableState();
}

class _AdminCompanyUsersTableState
    extends ConsumerState<AdminCompanyUsersTable> {
  final _verticalScrollController = ScrollController();
  final _horizScrollController = ScrollController();

  /// Which person a connection is currently being opened for. One at a time:
  /// starting a second connection revokes the first server-side, so letting two
  /// requests race would reliably leave the agent with a dead tab.
  String? _connectingUserId;

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizScrollController.dispose();
    super.dispose();
  }

  Future<void> _connect(AdminCompanyUserRow user) async {
    if (_connectingUserId != null) return;

    // Reserved on the tap itself, before the round trip, so the browser still
    // counts this as user-initiated. See ImpersonationLauncher.
    final reservedTab = widget.launcher.reserveTab();

    setState(() => _connectingUserId = user.userId);

    final l10n = AppLocalizations.of(context)!;

    try {
      final connection = await ref.read(adminServiceProvider).startImpersonation(
            companyId: widget.companyId,
            userId: user.userId,
          );

      if (reservedTab != null) {
        widget.launcher.navigate(reservedTab, connection.loginUrl);
        return;
      }

      // Popups blocked outright — hand the agent the link instead of failing
      // silently on a live support call.
      if (mounted) {
        await AdminImpersonationLinkDialog.show(
          context,
          loginUrl: connection.loginUrl,
          targetUserName: connection.targetUserName,
        );
      }
    } catch (_) {
      if (reservedTab != null) {
        widget.launcher.abandon(reservedTab);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminImpersonateFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _connectingUserId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: StickyReportTable(
        minWidth: AdminCompanyUsersColumns.minTableWidth,
        headerRow: const AdminCompanyUsersTableHeader(),
        loading: widget.isLoading,
        error: widget.hasError ? l10n.genericErrorRetry : null,
        body: widget.users.isEmpty
            // Three different facts, and two of them are actionable — clear the
            // search, or tick the deactivated box. They must not share a message.
            ? _EmptyBody(
                message: widget.isSearching
                    ? l10n.adminCompanyUsersNoMatches
                    : widget.companyHasAnyPeople
                        ? l10n.adminCompanyUsersNoneActive
                        : l10n.adminCompanyUsersEmpty,
              )
            : _Rows(
                users: widget.users,
                controller: _verticalScrollController,
                connectingUserId: _connectingUserId,
                onConnect: _connect,
              ),
        verticalScrollController: _verticalScrollController,
        horizontalScrollController: _horizScrollController,
      ),
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({
    required this.users,
    required this.controller,
    required this.connectingUserId,
    required this.onConnect,
  });

  final List<AdminCompanyUserRow> users;
  final ScrollController controller;
  final String? connectingUserId;
  final void Function(AdminCompanyUserRow) onConnect;

  @override
  Widget build(BuildContext context) {
    // No per-row keys: the rows are stateless, so there is no state for a key to
    // preserve, and a changing key forces a subtree re-insert under the
    // SelectableScope — the thing this table must not do.
    return ListView.builder(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      itemCount: users.length,
      itemBuilder: (context, index) => AdminCompanyUserTableRow(
        user: users[index],
        isEven: index.isEven,
        isConnecting: connectingUserId == users[index].userId,
        onConnect: () => onConnect(users[index]),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.mutedForeground,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
