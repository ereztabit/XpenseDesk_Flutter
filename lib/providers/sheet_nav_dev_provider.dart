import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/sheet_nav_dev_state.dart';

/// ENV=dev preview of the sheet-type bar. In any other environment it is pinned
/// to [SheetNavDevState.production] and every setter is a no-op, so a prod build
/// can never show mock budgets or overridden modules.
final sheetNavDevProvider =
    NotifierProvider<SheetNavDevNotifier, SheetNavDevState>(
      SheetNavDevNotifier.new,
    );

class SheetNavDevNotifier extends Notifier<SheetNavDevState> {
  @override
  SheetNavDevState build() => SheetNavDevState.production;

  void update(SheetNavDevState Function(SheetNavDevState) change) {
    if (!AppConfig.isDev) return;
    state = change(state);
  }
}
