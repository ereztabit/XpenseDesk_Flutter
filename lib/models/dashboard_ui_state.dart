/// Per-expense status bucket selected on the declined-sheet filter tabs.
enum FilterTab { rejected, pending, approved }

/// Mobile-only expenses-list layout switch. Persisted to SharedPreferences
/// under the `expense_layout_mode` key.
enum LayoutMode { card, list }
