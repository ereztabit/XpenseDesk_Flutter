import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/bulk_upload_utils.dart';

/// A progress bar for receipts being read in the background that keeps
/// moving between real updates (FS-1007): it eases forward through the
/// current file's fixed 40 s slot (`kBulkUploadSlotPerFile`) and holds just
/// short of the next file until the real update arrives. Never passes real
/// progress, so it never steps backwards. See `creepingProgress`.
///
/// Used by the My expenses progress strip and the notifications card.
class CreepingProgressBar extends StatefulWidget {
  const CreepingProgressBar({
    super.key,
    required this.done,
    required this.total,
    this.backgroundColor = AppTheme.muted,
    this.clock = DateTime.now,
  });

  final int done;
  final int total;
  final Color backgroundColor;

  /// Time source; tests pass a controllable one.
  final DateTime Function() clock;

  @override
  State<CreepingProgressBar> createState() => _CreepingProgressBarState();
}

class _CreepingProgressBarState extends State<CreepingProgressBar> {
  static const _tick = Duration(milliseconds: 250);

  late DateTime _lastChangeAt;
  late int _lastDone;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _lastChangeAt = widget.clock();
    _lastDone = widget.done;
    _syncTicker();
  }

  @override
  void didUpdateWidget(CreepingProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Any real change (forward, or a new run under the same bar) restarts
    // the current slot's clock.
    if (widget.done != _lastDone) {
      _lastDone = widget.done;
      _lastChangeAt = widget.clock();
    }
    _syncTicker();
  }

  void _syncTicker() {
    final running = widget.done < widget.total;
    if (running && _ticker == null) {
      _ticker = Timer.periodic(_tick, (_) {
        if (mounted) setState(() {});
      });
    } else if (!running) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = creepingProgress(
      done: widget.done,
      total: widget.total,
      sinceLastProgress: widget.clock().difference(_lastChangeAt),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 6,
        color: AppTheme.primary,
        backgroundColor: widget.backgroundColor,
      ),
    );
  }
}
