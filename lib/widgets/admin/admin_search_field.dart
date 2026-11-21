import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// The admin panel's search box.
///
/// Was `AdminCompaniesSearchField`, bound to the companies provider. Generalised
/// under FS-1001 when the people list needed the same box: rather than a second
/// near-identical widget, the provider wiring moved out to the callers and this
/// one keeps the look and the clear-button behaviour in a single place.
///
/// Client-side filtering everywhere it is used — the admin endpoints take no
/// query parameters and return their whole payload in one call, so there is
/// nothing to round-trip.
class AdminSearchField extends StatefulWidget {
  const AdminSearchField({
    super.key,
    required this.value,
    required this.hintText,
    required this.clearTooltip,
    required this.onChanged,
    this.compact = false,
  });

  /// Current query, owned by the caller's provider. Seeds the field on first
  /// build so it survives a rebuild with the query still applied.
  final String value;

  final String hintText;
  final String clearTooltip;
  final ValueChanged<String> onChanged;

  /// 40px tall, to sit in one row with 40px dropdowns and date filters
  /// (FS-1026 Receipt AI). Default false: the existing lists are unchanged.
  final bool compact;

  @override
  State<AdminSearchField> createState() => _AdminSearchFieldState();
}

class _AdminSearchFieldState extends State<AdminSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        isDense: widget.compact ? true : null,
        contentPadding: widget.compact ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10) : null,
        prefixIconConstraints: widget.compact ? const BoxConstraints(minWidth: 40, minHeight: 40) : null,
        suffixIconConstraints: widget.compact ? const BoxConstraints(minWidth: 40, minHeight: 40) : null,
        hintText: widget.hintText,
        filled: true,
        fillColor: AppTheme.card,
        suffixIcon: widget.value.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: widget.clearTooltip,
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              ),
      ),
    );
  }
}
