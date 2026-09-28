import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/bulk_upload_provider.dart';
import '../../providers/expense_sheet_provider.dart';
import '../../providers/navigation_guard_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_navigator.dart';
import '../../utils/bulk_upload_utils.dart';
import '../../utils/responsive_utils.dart';
import 'notifications_bell_icon.dart';
import 'notifications_panel.dart';

/// Header bell for the alerts center (FS-1007, UI/UX guide §6.1). Renders
/// nothing unless the company's bulk-upload flag is on — and only then
/// watches the batches, so a flag-off company never calls the endpoint.
///
/// Desktop: a 380-wide popover under the bell. Mobile: a bottom sheet up to
/// 85% of the screen.
class NotificationsBell extends ConsumerStatefulWidget {
  const NotificationsBell({super.key});

  @override
  ConsumerState<NotificationsBell> createState() => _NotificationsBellState();
}

class _NotificationsBellState extends ConsumerState<NotificationsBell> {
  static const double _popoverWidth = 380;

  final GlobalKey _bellKey = GlobalKey();
  OverlayEntry? _popover;

  @override
  void dispose() {
    _popover?.remove();
    _popover = null;
    super.dispose();
  }

  void _open() {
    final previousSeen = ref.read(notificationsLastSeenProvider);
    if (context.isMobile) {
      _openSheet(previousSeen);
    } else {
      _openPopover(previousSeen);
    }
  }

  void _openSheet(DateTime? previousSeen) {
    final height = MediaQuery.sizeOf(context).height;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.card,
      constraints: BoxConstraints(maxHeight: height * 0.85),
      builder: (sheetContext) => NotificationsPanel(
        previousSeen: previousSeen,
        maxListHeight: height * 0.85 - 64,
        onBatchTap: () {
          Navigator.of(sheetContext).pop();
          _openMyExpenses();
        },
      ),
    );
  }

  void _openPopover(DateTime? previousSeen) {
    final box = _bellKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final origin = box.localToGlobal(Offset.zero);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    _popover = OverlayEntry(builder: (ctx) {
      final screen = MediaQuery.sizeOf(ctx);
      final anchor =
          isRtl ? origin.dx + box.size.width - _popoverWidth : origin.dx;
      final left =
          anchor.clamp(8.0, screen.width - _popoverWidth - 8).toDouble();
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closePopover,
              behavior: HitTestBehavior.opaque,
            ),
          ),
          Positioned(
            top: origin.dy + box.size.height + 8,
            left: left,
            width: _popoverWidth,
            child: Material(
              color: AppTheme.card,
              elevation: 6,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: NotificationsPanel(
                previousSeen: previousSeen,
                maxListHeight: screen.height * 0.7,
                onBatchTap: () {
                  _closePopover();
                  _openMyExpenses();
                },
              ),
            ),
          ),
        ],
      );
    });
    Overlay.of(context).insert(_popover!);
  }

  void _closePopover() {
    _popover?.remove();
    _popover = null;
  }

  /// §6.3: a card opens My expenses (employee and manager alike), where the
  /// results are. Already there → just refresh the list.
  Future<void> _openMyExpenses() async {
    final route = ModalRoute.of(context)?.settings.name ?? '';
    final alreadyThere = route.startsWith(AppRoutes.employeeDashboard);
    if (!alreadyThere) {
      final guard = ref.read(navigationGuardProvider);
      final canLeave = guard == null || await guard();
      if (!canLeave || !mounted) return;
    }

    // The batch filed expenses behind the app's back: refetch both the list
    // (the sheet's count/total) and the detail family (its expense rows).
    ref.invalidate(mySheetsProvider);
    ref.invalidate(sheetDetailProvider);
    if (!alreadyThere) {
      Navigator.of(context).pushNamed(AppRoutes.employeeDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(isBulkUploadEnabledProvider)) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final batches = ref.watch(bulkUploadBatchesProvider).asData?.value ??
        const [];
    final lastSeen = ref.watch(notificationsLastSeenProvider);
    final isProcessing = hasProcessingBatch(batches);

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: NotificationsBellIcon(
        key: _bellKey,
        tooltip: isProcessing ? l10n.notifProcessingTooltip : l10n.notifTitle,
        unreadCount: unreadBatchCount(batches, lastSeen),
        isProcessing: isProcessing,
        onTap: _open,
      ),
    );
  }
}
