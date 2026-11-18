import 'package:flutter/material.dart';

import '../../models/status_counter.dart';
import '../../utils/responsive_utils.dart';
import 'counter_card.dart';
import 'sheets_summary_mobile_card.dart';

/// A dashboard counters block (§3, §4), data-driven: desktop = equal-height
/// [CounterCard]s in one row, mobile = one [SheetsSummaryMobileCard] with a
/// column per counter. Monthly ([SheetCounterCards]) and Budgets feed it.
class StatusCounterCards extends StatelessWidget {
  const StatusCounterCards({
    super.key,
    required this.counters,
    required this.mobileTitle,
    this.mobileLinkLabel,
  });

  final List<StatusCounter> counters;
  final String mobileTitle;

  /// Caption of each mobile column's link; null = the Monthly "View More".
  final String? mobileLinkLabel;

  static const double _kDesktopCardMinHeight = 150;

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return SheetsSummaryMobileCard(
        title: mobileTitle,
        counters: counters,
        linkLabel: mobileLinkLabel,
      );
    }

    // `IntrinsicHeight` bounds the Row so `stretch` is safe inside the
    // dashboard's vertical scroll view; `minHeight` is the floor.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < counters.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: CounterCard(
                count: counters[i].count,
                label: counters[i].label,
                eyebrow: counters[i].eyebrow,
                icon: counters[i].icon,
                alert: counters[i].alert,
                minHeight: _kDesktopCardMinHeight,
                onTap: counters[i].onTap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
