import 'dart:async';

import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../utils/bulk_upload_copy_utils.dart';
import 'bulk_upload_amber_notice.dart';

/// "Removed 2 unsupported files: notes.docx, photo.heic" — shown about 5 s,
/// fading from 4.5 s (UI/UX guide §3.3). Key it by the notice id so a new add
/// restarts the timer.
class BulkUploadUnsupportedNotice extends StatefulWidget {
  const BulkUploadUnsupportedNotice({
    super.key,
    required this.names,
    required this.onExpired,
  });

  final List<String> names;
  final VoidCallback onExpired;

  @override
  State<BulkUploadUnsupportedNotice> createState() =>
      _BulkUploadUnsupportedNoticeState();
}

class _BulkUploadUnsupportedNoticeState
    extends State<BulkUploadUnsupportedNotice> {
  Timer? _fadeTimer;
  Timer? _expireTimer;
  bool _fading = false;

  @override
  void initState() {
    super.initState();
    _fadeTimer = Timer(const Duration(milliseconds: 4500), () {
      if (mounted) setState(() => _fading = true);
    });
    _expireTimer = Timer(const Duration(seconds: 5), widget.onExpired);
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _expireTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = joinWords([
      l10n.bulkUploadUnsupportedPrefix,
      '${widget.names.length}',
      l10n.bulkUploadUnsupportedSuffix,
      widget.names.join(', '),
    ]);
    return AnimatedOpacity(
      opacity: _fading ? 0 : 1,
      duration: const Duration(milliseconds: 500),
      child: BulkUploadAmberNotice(message: message),
    );
  }
}
