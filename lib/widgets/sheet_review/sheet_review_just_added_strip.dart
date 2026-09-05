import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// FS-1004. A one-shot animated cue shown after a manager files a line onto the
/// sheet, naming what was just added.
///
/// It exists because a manager-filed line is approved on entry and therefore
/// lands in the **Approved** bucket, while Sheet Review opens on Pending — so
/// without a cue the expense looks like it was never saved. The section switches
/// to the Approved tab at the same time; this strip is what draws the eye to it.
///
/// Deliberately a sibling ABOVE the line list rather than a highlight on the row
/// itself: the desktop table wraps its rows in a SelectionArea, and a row that
/// rebuilds on an animation ticker re-registers its selectables on every frame
/// and trips `SelectableRegion: _selectable == null is not true` (see the
/// StickyReportTable note in CLAUDE.md). Animating outside the selectable region
/// gets the same attention with none of that risk.
class SheetReviewJustAddedStrip extends StatefulWidget {
  const SheetReviewJustAddedStrip({
    super.key,
    required this.description,
    required this.onFinished,
  });

  /// What was added, already formatted by the caller (merchant + amount in the
  /// company locale and base currency).
  final String description;

  /// Called once the cue has faded out, so the caller can drop it from the tree.
  final VoidCallback onFinished;

  @override
  State<SheetReviewJustAddedStrip> createState() =>
      _SheetReviewJustAddedStripState();
}

class _SheetReviewJustAddedStripState extends State<SheetReviewJustAddedStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    // 4s total: ~0.35s in, ~3s hold, ~0.65s out.
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 9),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 75),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 16),
    ]).animate(_controller);

    _slide = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.09, curve: Curves.easeOut),
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onFinished();
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.success.withAlpha(20),
            border: Border.all(color: AppTheme.success.withAlpha(102)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 18,
                color: AppTheme.success,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.sheetReviewJustAdded,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
