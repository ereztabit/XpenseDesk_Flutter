import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dashboard_ui_state.dart';
import '../../providers/employee_dashboard_provider.dart';
import '../../theme/app_theme.dart';

/// Square 32×32 ghost icon button. Icon swaps between list and gallery to
/// communicate the next mode (currently in card view → list icon, currently
/// in list view → gallery icon).
///
/// Mobile only; the orchestrator hides this on desktop and when the sheet
/// is not an editable Draft / no expenses are rendered.
class ViewModeToggle extends ConsumerWidget {
  const ViewModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(expenseLayoutModeProvider);
    final nextIsList = mode == LayoutMode.card;
    final icon = nextIsList ? Icons.view_list_outlined : Icons.grid_view_outlined;

    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () =>
              ref.read(expenseLayoutModeProvider.notifier).toggle(),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderMedium),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.foreground),
          ),
        ),
      ),
    );
  }
}
