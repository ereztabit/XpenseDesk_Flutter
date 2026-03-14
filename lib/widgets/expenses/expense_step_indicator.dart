import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class ExpenseStepIndicator extends StatelessWidget {
  final int currentStep;

  const ExpenseStepIndicator({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.newExpenseStepUpload,
      l10n.newExpenseStepDetails,
      l10n.newExpenseStepApproval,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < labels.length; i++) ...[
          if (i > 0) _buildConnector(i - 1),
          _buildStep(i, labels[i]),
        ],
      ],
    );
  }

  Widget _buildStep(int index, String label) {
    final isActive = index == currentStep;
    final isCompleted = index < currentStep;

    final Color circleColor;
    final Widget circleChild;
    final Color labelColor;

    if (isCompleted) {
      circleColor = AppTheme.primary.withAlpha(51);
      circleChild = Icon(Icons.check, size: 16, color: AppTheme.primary);
      labelColor = AppTheme.mutedForeground;
    } else if (isActive) {
      circleColor = AppTheme.primary;
      circleChild = Text(
        '${index + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
      labelColor = AppTheme.foreground;
    } else {
      circleColor = AppTheme.muted;
      circleChild = Text(
        '${index + 1}',
        style: const TextStyle(
          color: AppTheme.mutedForeground,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
      labelColor = AppTheme.mutedForeground;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: circleChild,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(int beforeIndex) {
    final isCompleted = beforeIndex < currentStep;
    return Padding(
      // Center connector with the 32px circle (16px from top = circle center)
      padding: const EdgeInsets.only(top: 15.5),
      child: Container(
        width: 48,
        height: 1,
        color: isCompleted
            ? AppTheme.primary.withAlpha(102)
            : AppTheme.border,
      ),
    );
  }
}
