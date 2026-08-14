import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/utils/admin_format_utils.dart';

/// The admin shell pins its formatting to Israel time rather than the browser's
/// timezone, using the DST rule in force since 2013: DST runs from 02:00 on the
/// Friday before the last Sunday of March to 02:00 on the last Sunday of
/// October. These cases pin the boundaries, which is where a hand-rolled rule
/// goes wrong.
void main() {
  group('toIsraelTime', () {
    test('winter instant is UTC+2', () {
      final result = DateTime.utc(2026, 1, 15, 10, 0).toIsraelTime();
      expect(result.hour, 12);
      expect(result.day, 15);
    });

    test('summer instant is UTC+3', () {
      final result = DateTime.utc(2026, 6, 20, 7, 11, 21).toIsraelTime();
      expect(result.hour, 10);
      expect(result.minute, 11);
      expect(result.day, 20);
    });

    test('2026 DST starts on Friday 27 March at 00:00 UTC', () {
      // Last Sunday of March 2026 is the 29th, so DST starts Friday the 27th.
      expect(DateTime.utc(2026, 3, 26, 23, 59).toIsraelTime().hour, 1);
      expect(DateTime.utc(2026, 3, 27, 0, 0).toIsraelTime().hour, 3);
    });

    test('2026 DST ends on Saturday 24 October at 23:00 UTC', () {
      // Last Sunday of October 2026 is the 25th; 02:00 IDT == 23:00 UTC on the
      // 24th.
      expect(DateTime.utc(2026, 10, 24, 22, 59).toIsraelTime().hour, 1);
      expect(DateTime.utc(2026, 10, 24, 23, 0).toIsraelTime().hour, 1);
    });

    test('2027 boundaries move with the calendar', () {
      // Last Sunday of March 2027 is the 28th -> DST starts Friday the 26th.
      expect(DateTime.utc(2027, 3, 25, 12, 0).toIsraelTime().hour, 14);
      expect(DateTime.utc(2027, 3, 26, 12, 0).toIsraelTime().hour, 15);
    });

    test('the result is local-flagged so format_utils leaves it alone', () {
      final result = DateTime.utc(2026, 6, 20, 7, 11, 21).toIsraelTime();
      expect(result.isUtc, isFalse);
      expect(result.toLocal(), result);
    });
  });
}
