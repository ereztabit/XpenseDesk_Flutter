// Sheet Review opens on Pending only while lines await a decision; a decided
// sheet opens on its first non-empty bucket, never on an empty list.
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/dashboard_ui_state.dart';
import 'package:xpensedesk_flutter/utils/sheet_utils.dart';

FilterTab _tab({int pending = 0, int approved = 0, int rejected = 0}) =>
    SheetExpenseBuckets.initialTab({
      FilterTab.pending: pending,
      FilterTab.approved: approved,
      FilterTab.rejected: rejected,
    });

void main() {
  test('pending lines win, even when other buckets have more', () {
    expect(_tab(pending: 1, approved: 5, rejected: 2), FilterTab.pending);
  });

  test('approved sheet opens on Approved', () {
    expect(_tab(approved: 4), FilterTab.approved);
  });

  test('decided sheet with approved and declined lines opens on Approved', () {
    expect(_tab(approved: 1, rejected: 3), FilterTab.approved);
  });

  test('all-declined sheet opens on Declined', () {
    expect(_tab(rejected: 2), FilterTab.rejected);
  });

  test('empty sheet falls back to Pending', () {
    expect(_tab(), FilterTab.pending);
  });
}
