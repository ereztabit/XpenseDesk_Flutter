import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_import_check.dart';
import '../../../providers/admin_receipt_ai_provider.dart';
import '../../../services/admin_service.dart' show AdminException;
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_display_utils.dart';
import '../../../utils/web_file_picker.dart';
import '../../app_button.dart';
import 'ai_import_report.dart';

/// Largest profile file read in the browser (the server takes 200,000 characters).
const int kAiImportMaxBytes = 800 * 1024;

/// Import from ReceiptLab: pick the lab's prompt file (.txt), see the server's
/// check, then create the draft. Pops `true` when a draft was created.
class AiImportDialog extends ConsumerStatefulWidget {
  const AiImportDialog({super.key, required this.profileId});

  final int profileId;

  static Future<bool> show(BuildContext context, {required int profileId}) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AiImportDialog(profileId: profileId),
      ) ??
      false;

  @override
  ConsumerState<AiImportDialog> createState() => _AiImportDialogState();
}

class _AiImportDialogState extends ConsumerState<AiImportDialog> {
  String? _fileName;
  String? _content;
  AdminAiImportCheck? _check;
  bool _busy = false;

  Future<void> _pick() async {
    final l10n = AppLocalizations.of(context)!;
    final files = await pickWebFiles(const ['.txt']);
    if (files.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      final file = files.first;
      if (file.size > kAiImportMaxBytes) {
        showAdminAiSnack(context, l10n.adminAiErrFileInvalid, error: true);
        return;
      }
      final content = utf8.decode(await readWebFileBytes(file), allowMalformed: true);
      final check = await ref
          .read(adminAiProfilesServiceProvider)
          .checkImport(widget.profileId, fileName: file.name, content: content);
      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _content = content;
        _check = check;
      });
    } catch (e) {
      if (mounted) showAdminAiSnack(context, adminAiErrorMessage(l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await ref
          .read(adminAiProfilesServiceProvider)
          .importFile(widget.profileId, fileName: _fileName!, content: _content!);
      if (!mounted) return;
      showAdminAiSnack(context, l10n.adminAiImported);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAdminAiSnack(context, adminAiErrorMessage(l10n, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final check = _check;

    return AlertDialog(
      title: Text(l10n.adminAiImport, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.adminAiImportBody, style: const TextStyle(fontSize: 14, color: AppTheme.mutedForeground)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppButton(
                    label: l10n.adminAiChooseFile,
                    variant: AppButtonVariant.normal,
                    icon: Icons.upload_file_outlined,
                    onPressed: _busy ? null : _pick,
                  ),
                  if (_fileName != null)
                    Text(_fileName!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              if (check != null) ...[
                const SizedBox(height: 14),
                AiImportReport(check: check),
                if (check.errorCode != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    adminAiErrorMessage(l10n, AdminException('', errorCode: check.errorCode)),
                    style: const TextStyle(fontSize: 13, color: AppTheme.destructive),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        AppButton(
          label: l10n.cancel,
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: l10n.adminAiCreateDraft,
          isLoading: _busy && check != null,
          onPressed: check == null || !check.canImport || _busy ? null : _import,
        ),
      ],
    );
  }
}
