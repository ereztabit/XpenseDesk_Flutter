// The bulk-upload progress bar keeps moving between real updates (FS-1007):
// it creeps through the current file's slot, holds just short of the next
// file, and snaps to real progress when an update lands — never backwards.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/widgets/bulk_upload/creeping_progress_bar.dart';

void main() {
  testWidgets('creeps, holds, snaps to real progress, keeps a fixed pace',
      (tester) async {
    var now = DateTime(2026, 9, 28, 12);
    Widget bar(int done) => MaterialApp(
          home: Scaffold(
            body: CreepingProgressBar(done: done, total: 4, clock: () => now),
          ),
        );
    double value() => tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value!;
    Future<void> advance(Duration d) async {
      now = now.add(d);
      await tester.pump(const Duration(milliseconds: 300));
    }

    await tester.pumpWidget(bar(0));
    expect(value(), 0);

    // Default pace 40 s/file: moving, but still inside file 1's slot.
    await advance(const Duration(seconds: 20));
    final creeping = value();
    expect(creeping, greaterThan(0));
    expect(creeping, lessThan(0.25));

    // Past the expected time: holds at 90% of the slot, no further.
    await advance(const Duration(seconds: 120));
    expect(value(), closeTo(0.9 / 4, 1e-9));

    // A real update: jumps to exactly one file done — forward, never back.
    await tester.pumpWidget(bar(1));
    expect(value(), closeTo(0.25, 1e-9));

    // A file that fails fast (lands after 2 s) does not change the pace: the
    // slot stays a fixed 40 s, so 20 s into slot 3 the bar is exactly where
    // the fixed slot puts it (0.9 × ease-out(0.5) of a quarter).
    await advance(const Duration(seconds: 2));
    await tester.pumpWidget(bar(2));
    await advance(const Duration(seconds: 20));
    expect(value(), closeTo((2 + 0.9 * (1 - 0.5 * 0.5)) / 4, 1e-9));

    // Done: full, and the ticker stops (no pending timer at test end).
    await tester.pumpWidget(bar(4));
    expect(value(), 1);
  });
}
