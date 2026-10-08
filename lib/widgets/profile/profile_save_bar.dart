import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../utils/responsive_utils.dart';
import '../app_button.dart';
import '../error_alert.dart';
import 'profile_success_banner.dart';

/// Bottom of the profile form: the success banner or error alert of the last
/// save, then the Save button — full-width on narrow screens for a comfortable
/// tap target, directional-end (RTL-correct) on wider ones.
class ProfileSaveBar extends StatelessWidget {
  const ProfileSaveBar({
    super.key,
    required this.successMessage,
    required this.errorMessage,
    required this.isSaving,
    required this.onSave,
  });

  final String? successMessage;
  final String? errorMessage;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final button = AppButton(
      label: l10n.saveChanges,
      variant: AppButtonVariant.primary,
      isLoading: isSaving,
      onPressed: isSaving ? null : onSave,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (successMessage != null) ...[
          ProfileSuccessBanner(message: successMessage!),
          const SizedBox(height: 16),
        ],
        if (errorMessage != null) ...[
          ErrorAlert(message: errorMessage!),
          const SizedBox(height: 16),
        ],
        if (context.isNarrow)
          SizedBox(width: double.infinity, child: button)
        else
          Align(alignment: AlignmentDirectional.centerEnd, child: button),
      ],
    );
  }
}
