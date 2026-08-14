/// Formatting rules for the platform-admin shell.
///
/// The admin has **no customer company**, so it cannot read a formatting locale
/// the way the rest of the app does (`companyLocaleProvider`). The hidden
/// platform company that carries the admin session is an internal seed row —
/// its locale/currency columns exist only to satisfy NOT NULL constraints and
/// must never be treated as authoritative.
///
/// So the admin panel pins Israel conventions and feeds them into the
/// `format_utils.dart` extensions, exactly as every other screen does with the
/// company locale. This is independent of the UI language: an English-reading
/// admin still sees `14.8.2026` and `₪`.
///
/// Revisit if XpenseDesk ever serves non-Israeli companies — the shekel and the
/// timezone assumption both live here.
library;

/// Formatting locale for every date/amount in the admin shell.
/// **Not** the UI language — never pass `Localizations.localeOf(context)` here.
///
/// There is deliberately no currency constant beside this one: V1 renders no
/// amounts. The first admin module that shows money declares `'ILS'` next to
/// its first use rather than inheriting an unused constant that looks wired up.
const String kAdminFormatLocale = 'he';

/// Renders a UTC instant as Israel wall-clock time.
///
/// The API returns ISO-8601 UTC; the browser's own timezone is irrelevant to an
/// admin looking at platform-wide data, so timestamps are pinned to Israel
/// (UTC+2, UTC+3 during DST) rather than converted with `toLocal()`.
///
/// The returned value is a **local-flagged** `DateTime` carrying Israel
/// wall-clock components, so the `format_utils.dart` extensions (which call
/// `toLocal()`) leave it untouched.
extension IsraelTime on DateTime {
  DateTime toIsraelTime() {
    final utc = toUtc().add(_israelUtcOffset(toUtc()));
    return DateTime(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
    );
  }
}

/// Israel's UTC offset for [utc], per the rule in force since 2013: DST runs
/// from 02:00 on the Friday before the last Sunday of March to 02:00 on the
/// last Sunday of October.
Duration _israelUtcOffset(DateTime utc) {
  final year = utc.year;
  // 02:00 IST (UTC+2) on that Friday == 00:00 UTC.
  final dstStart = DateTime.utc(year, 3, _lastSundayOfMonth(year, 3) - 2);
  // 02:00 IDT (UTC+3) on that Sunday == 23:00 UTC the day before.
  final dstEnd = DateTime.utc(year, 10, _lastSundayOfMonth(year, 10))
      .subtract(const Duration(hours: 1));

  final inDst = !utc.isBefore(dstStart) && utc.isBefore(dstEnd);
  return Duration(hours: inDst ? 3 : 2);
}

/// Day-of-month of the last Sunday in [month].
int _lastSundayOfMonth(int year, int month) {
  final lastDay = DateTime.utc(year, month + 1, 0).day;
  // DateTime.weekday is Mon=1..Sun=7; `% 7` maps Sunday to 0.
  return lastDay - (DateTime.utc(year, month, lastDay).weekday % 7);
}
