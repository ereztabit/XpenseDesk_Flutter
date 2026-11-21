// FS-1026 aesthetics round 2 - the Profiles table fits without a sideways
// scrollbar from a 768px screen up; Name takes the room left.
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/utils/admin_ai_table_layout_utils.dart';

double _total(double available) {
  final l = aiProfileTableLayout(available);
  return l.number + l.name + l.status + l.companies + l.published + l.draft + l.lastChanged + 128 + 10;
}

void main() {
  _roundThree();

  test('a 768px screen (720px content): everything fits, Last changed left out', () {
    final l = aiProfileTableLayout(720);
    expect(l.showLastChanged, isFalse);
    expect(_total(720), lessThanOrEqualTo(720));
    expect(l.name, greaterThanOrEqualTo(150));
  });

  test('870px (narrow desktop): fits, Name grows', () {
    expect(_total(822), lessThanOrEqualTo(822));
    expect(aiProfileTableLayout(822).name, greaterThan(aiProfileTableLayout(720).name));
  });

  test('wide: Last changed shown and Name takes the rest exactly', () {
    final l = aiProfileTableLayout(1232);
    expect(l.showLastChanged, isTrue);
    expect(_total(1232), closeTo(1232, 0.01));
  });

  test('below the minimum it scrolls rather than squeezing Name', () {
    expect(aiProfileTableLayout(400).name, 150);
    expect(_total(400), greaterThan(400));
  });
}

// Round 3 - the other Receipt AI tables fit too, action column included.
double _fitTotal(List<double?> widths) => widths.fold(10.0, (a, w) => a + (w ?? 0));

void _expectFits(String name, List<AiFitColumn> cols, int flex, double minFlex) {
  group(name, () {
    for (final width in [720.0, 822.0, 1232.0]) {
      test('fits at $width, flexible column at least $minFlex', () {
        final w = aiFitColumns(width, cols, flex: flex, minFlex: minFlex);
        expect(_fitTotal(w), closeTo(width, 0.01));
        expect(w[flex], greaterThanOrEqualTo(minFlex));
        expect(w.last ?? w[w.length - 1], isNotNull, reason: 'the last column is never left out');
      });
    }

    test('wide: nothing left out', () {
      expect(aiFitColumns(1232, cols, flex: flex, minFlex: minFlex), isNot(contains(null)));
    });

    test('below the minimum it scrolls rather than squeezing', () {
      final w = aiFitColumns(300, cols, flex: flex, minFlex: minFlex);
      expect(w[flex], minFlex);
      expect(_fitTotal(w), greaterThan(300));
    });
  });
}

void _roundThree() {
  _expectFits('Usage table', aiUsageTableColumns, 0, 200);
  _expectFits('Scan list', aiScanListColumns, 1, 140);
  _expectFits('Companies table', aiCompaniesTableColumns, 1, 200);
  _expectFits('Versions table', aiVersionsTableColumns, 3, 160);

  test('cells and columns drop the same left-out columns', () {
    final w = aiFitColumns(720, aiUsageTableColumns, flex: 0, minFlex: 200);
    final labels = ['m', 'u', 'v', 'c', 'n', 'a', ''];
    expect(aiFitTableColumns(labels, w).map((c) => c.label), aiFitCells(labels, w));
    expect(aiFitCells(labels, w), isNot(contains('n')));
  });
}
