import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/admin_company_user_row.dart';
import '../../theme/app_theme.dart';
import '../action_icon_button.dart';
import 'admin_company_users_table_header.dart';

/// One person, with the Connect action.
///
/// **Stateless, with zebra striping instead of a hover tint — deliberately, and
/// it must stay that way.** This row lives inside [StickyReportTable]'s
/// `SelectableScope`, and a `setState` on hover re-registers the row's `Text`
/// selectables on every mouse move, which trips the framework assertion
/// `SelectableRegion: _selectable == null is not true` (see the NOTE in
/// `selectable_scope.dart`).
///
/// That same NOTE is why there is **no `SelectionContainer.disabled`** anywhere
/// in this row: a `SelectionContainer` inserted under a `SelectionArea` is the
/// other half of the same assertion, and it fired on every cold mount of this
/// screen. A bare [ActionIconButton] is safe and is what the other tables use.
class AdminCompanyUserTableRow extends StatelessWidget {
  const AdminCompanyUserTableRow({
    super.key,
    required this.user,
    required this.isEven,
    required this.isConnecting,
    required this.onConnect,
  });

  final AdminCompanyUserRow user;
  final bool isEven;

  /// A connection is being opened for THIS person. The action is replaced by a
  /// spinner so a second tap cannot mint a second link — which would revoke the
  /// first one server-side and leave the agent with a dead tab.
  final bool isConnecting;

  final VoidCallback onConnect;

  static const _cellStyle = TextStyle(fontSize: 13, color: AppTheme.foreground);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: isEven ? AppTheme.muted.withAlpha(25) : null,
        border: const Border(
          bottom: BorderSide(color: AppTheme.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _Cell(
            width: AdminCompanyUsersColumns.name,
            child: Row(
              children: [
                // Connect LEADS the row, before the name: it is the only action
                // on the page, so it belongs where the eye starts, at a fixed
                // position every row shares. A trailing control is the first
                // thing off-screen on a phone, and one that follows a
                // variable-length name never lands twice in the same place.
                //
                // Deactivated people get a same-size blank rather than no cell,
                // so the names below still line up. No disabled button: the
                // server refuses them, so offering one would be a promise the
                // API will not keep.
                //
                // Do NOT wrap this in SelectionContainer.disabled. It looks like
                // the right way to keep a hover-restyling button out of the
                // enclosing SelectionArea, but SelectionContainer.disabled IS a
                // SelectionContainer, and inserting one under a SelectionArea is
                // the precise trigger for `SelectableRegion: _selectable == null
                // is not true` — see the NOTE in selectable_scope.dart. A bare
                // ActionIconButton is what the other tables use and is safe; the
                // rule this table must keep is no setState on the ROW.
                SizedBox(
                  width: 32,
                  height: 32,
                  child: !user.isActive
                      ? null
                      : isConnecting
                          ? const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : ActionIconButton(
                              // Not Icons.login — that glyph is an arrow into a
                              // door, which reads as sign-out and sat one row
                              // away from the real Disconnect. This one says
                              // "become someone else", which is the action.
                              icon: Icons.switch_account_outlined,
                              tooltip: l10n.adminImpersonateConnect,
                              color: AppTheme.primary,
                              onPressed: onConnect,
                            ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    user.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      // A deactivated person is shown greyed rather than merely
                      // labelled, so the agent's eye skips them while scanning.
                      color: user.isActive
                          ? AppTheme.foreground
                          : AppTheme.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _Cell(
            width: AdminCompanyUsersColumns.email,
            child: Text(
              user.email,
              overflow: TextOverflow.ellipsis,
              style: _cellStyle,
            ),
          ),
          _Cell(
            width: AdminCompanyUsersColumns.role,
            child: Text(
              user.isManager ? l10n.adminRoleManager : l10n.adminRoleEmployee,
              style: _cellStyle,
            ),
          ),
          _Cell(
            width: AdminCompanyUsersColumns.status,
            child: Text(_statusLabel(l10n), style: _cellStyle),
          ),
        ],
      ),
    );
  }

  /// `status` and `isActive` are different facts: `Pending` means invited but
  /// never signed in, deactivated means signed in and later switched off. The
  /// deactivated state wins the label because it is the one that decides whether
  /// this person can be connected as.
  String _statusLabel(AppLocalizations l10n) {
    if (!user.isActive) return l10n.adminUserDeactivated;
    if (user.status == 'Pending') return l10n.adminUserPending;
    return l10n.adminUserActive;
  }
}

/// Fixed-width cell matching the header's padding, so columns line up under the
/// shared horizontal scroll.
class _Cell extends StatelessWidget {
  const _Cell({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      alignment: AlignmentDirectional.centerStart,
      child: child,
    );
  }
}
