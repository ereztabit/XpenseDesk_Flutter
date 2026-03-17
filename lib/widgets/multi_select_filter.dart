import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// A filter control that renders a labelled [OutlinedButton] and opens an
/// [AlertDialog] with a scrollable list of checkboxes.
///
/// In [singleSelect] mode, selecting an item deselects all others (radio-like).
/// In multi-select mode (default), a "Select All / Clear" row is shown above
/// the list and multiple items can be active simultaneously.
class MultiSelectFilter<T> extends StatelessWidget {
  final String sectionLabel;
  final String dialogTitle;
  final String buttonLabel;
  final List<T> allItems;
  final String Function(T) itemLabel;
  final Set<T> selected;
  final void Function(Set<T>) onChanged;
  final bool enabled;
  final bool singleSelect;

  const MultiSelectFilter({
    super.key,
    required this.sectionLabel,
    required this.dialogTitle,
    required this.buttonLabel,
    required this.allItems,
    required this.itemLabel,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.singleSelect = false,
  });

  Future<void> _show(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final working = Set<T>.from(selected);

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(dialogTitle),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!singleSelect) ...[
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setS(() => working.addAll(allItems)),
                        child: Text(l10n.selectAll),
                      ),
                      TextButton(
                        onPressed: () => setS(() => working.clear()),
                        child: Text(l10n.clear),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: SingleChildScrollView(
                    child: Column(
                      children: allItems.map((item) {
                        return CheckboxListTile(
                          value: working.contains(item),
                          onChanged: (v) => setS(() {
                            if (singleSelect) {
                              working.clear();
                              if (v == true) working.add(item);
                            } else {
                              if (v == true) {
                                working.add(item);
                              } else {
                                working.remove(item);
                              }
                            }
                          }),
                          title: Text(
                            itemLabel(item),
                            style: const TextStyle(fontSize: 14),
                          ),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.done),
            ),
          ],
        ),
      ),
    );

    onChanged(working);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionLabel.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.mutedForeground,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: enabled ? () => _show(context) : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(color: AppTheme.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              foregroundColor: AppTheme.foreground,
              alignment: AlignmentDirectional.centerStart,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                buttonLabel,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
