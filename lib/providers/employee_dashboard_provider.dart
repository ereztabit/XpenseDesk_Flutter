import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_ui_state.dart';

/// Picker selection: the sheet id whose expenses the screen currently shows.
///
/// `null` means "not yet resolved" — on first load, the picker widget reads
/// `mySheetsProvider`, finds the current-cycle Draft, and writes its id here.
/// Falls back to the picker default when the selected id 404s
/// (e.g. a Declined sheet auto-deleted server-side after its last expense was
/// removed).
class SelectedSheetIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

final selectedSheetIdProvider =
    NotifierProvider<SelectedSheetIdNotifier, String?>(
  SelectedSheetIdNotifier.new,
);

/// Active per-expense bucket on the Submitted / Declined sheet filter tabs.
/// Defaults to Pending — the tabs show all three buckets (even at count 0),
/// so Pending is the most useful landing bucket across both sheet states.
class SelectedFilterTabNotifier extends Notifier<FilterTab> {
  @override
  FilterTab build() => FilterTab.pending;

  void set(FilterTab tab) => state = tab;
}

final selectedFilterTabProvider =
    NotifierProvider<SelectedFilterTabNotifier, FilterTab>(
  SelectedFilterTabNotifier.new,
);

/// Tracks the sheet id for which the per-sheet default filter tab has been
/// applied. On first entry to a sheet's tabbed view the active tab is set to a
/// sensible default (a Declined sheet with declined expenses focuses the
/// Declined bucket; every other tabbed sheet focuses Pending), once per sheet id
/// -- so it never re-applies on rebuild or fights a manual tab choice. See
/// employee_dashboard_body.dart.
class TabFocusedSheetNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? sheetId) => state = sheetId;
}

final tabFocusedSheetProvider =
    NotifierProvider<TabFocusedSheetNotifier, String?>(
  TabFocusedSheetNotifier.new,
);

/// Tracks which set of returned sheets the user has already dismissed the
/// global alert for. The key is `sorted returned-sheet ids joined by '|'` —
/// when the set changes, the key changes and the alert reappears.
class DismissedReturnedAlertKeyNotifier extends Notifier<String?> {
  static const _prefsKey = 'returned_alert_dismissed_key';

  @override
  String? build() {
    _loadFromPrefs();
    return null;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null) state = stored;
  }

  Future<void> dismiss(String key) async {
    state = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, key);
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

final dismissedReturnedAlertKeyProvider =
    NotifierProvider<DismissedReturnedAlertKeyNotifier, String?>(
  DismissedReturnedAlertKeyNotifier.new,
);

/// Mobile layout switch (card carousel vs. compact list). Persisted across
/// sessions; defaults to card.
class ExpenseLayoutModeNotifier extends Notifier<LayoutMode> {
  static const _prefsKey = 'expense_layout_mode';

  @override
  LayoutMode build() {
    _loadFromPrefs();
    return LayoutMode.card;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored == LayoutMode.list.name) {
      state = LayoutMode.list;
    } else if (stored == LayoutMode.card.name) {
      state = LayoutMode.card;
    }
  }

  Future<void> set(LayoutMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }

  Future<void> toggle() async {
    await set(state == LayoutMode.card ? LayoutMode.list : LayoutMode.card);
  }
}

final expenseLayoutModeProvider =
    NotifierProvider<ExpenseLayoutModeNotifier, LayoutMode>(
  ExpenseLayoutModeNotifier.new,
);
