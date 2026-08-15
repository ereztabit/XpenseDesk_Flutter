import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/admin_companies_sort.dart';
import 'package:xpensedesk_flutter/models/admin_company_row.dart';
import 'package:xpensedesk_flutter/utils/admin_companies_utils.dart';

AdminCompanyRow _row({
  required String name,
  required DateTime created,
  String paymentStatus = 'Active',
  bool isActive = true,
  int users = 0,
  int expenses = 0,
}) {
  return AdminCompanyRow(
    companyId: name,
    companyName: name,
    creationDate: created,
    paymentStatus: paymentStatus,
    isActive: isActive,
    companyStatus: 'Active',
    userCount: users,
    expenseCount: expenses,
  );
}

List<String> _names(List<AdminCompanyRow> rows) =>
    rows.map((r) => r.companyName).toList();

void main() {
  final alpha = _row(
    name: 'Alpha',
    created: DateTime.utc(2026, 1, 1),
    users: 10,
    expenses: 5,
  );
  final bravo = _row(
    name: 'bravo',
    created: DateTime.utc(2026, 3, 1),
    paymentStatus: 'PendingPayment',
    users: 2,
    expenses: 40,
  );
  final charlie = _row(
    name: 'Charlie',
    created: DateTime.utc(2026, 2, 1),
    // Deactivated: the server reports PendingPayment for these, which is
    // exactly what must NOT drive the sort.
    paymentStatus: 'PendingPayment',
    isActive: false,
    users: 7,
    expenses: 1,
  );
  final rows = [alpha, bravo, charlie];

  group('filterByName', () {
    test('is case-insensitive and matches a substring', () {
      expect(_names(AdminCompaniesQuery.filterByName(rows, 'RAV')), ['bravo']);
    });

    test('a blank or whitespace-only query matches everything', () {
      expect(AdminCompaniesQuery.filterByName(rows, '   '), hasLength(3));
      expect(AdminCompaniesQuery.filterByName(rows, ''), hasLength(3));
    });

    test('no match returns empty, not everything', () {
      expect(AdminCompaniesQuery.filterByName(rows, 'zzz'), isEmpty);
    });
  });

  group('sorted', () {
    test('name sorts case-insensitively', () {
      final result = AdminCompaniesQuery.sorted(
        rows,
        const AdminCompaniesSort(
          column: AdminCompanySortColumn.name,
          ascending: true,
        ),
      );
      expect(_names(result), ['Alpha', 'bravo', 'Charlie']);
    });

    test('creation date descending is the initial order', () {
      final result = AdminCompaniesQuery.sorted(rows, AdminCompaniesSort.initial);
      expect(_names(result), ['bravo', 'Charlie', 'Alpha']);
    });

    test('payment status sorts on the displayed state, not the raw string', () {
      // bravo and charlie both carry paymentStatus 'PendingPayment' on the
      // wire; charlie is deactivated and must sort after it, not beside it.
      final result = AdminCompaniesQuery.sorted(
        rows,
        const AdminCompaniesSort(
          column: AdminCompanySortColumn.paymentStatus,
          ascending: true,
        ),
      );
      expect(_names(result), ['Alpha', 'bravo', 'Charlie']);
    });

    test('counts sort numerically in both directions', () {
      const desc = AdminCompaniesSort(
        column: AdminCompanySortColumn.expenseCount,
        ascending: false,
      );
      expect(_names(AdminCompaniesQuery.sorted(rows, desc)),
          ['bravo', 'Alpha', 'Charlie']);
      expect(
        _names(AdminCompaniesQuery.sorted(
          rows,
          const AdminCompaniesSort(
            column: AdminCompanySortColumn.userCount,
            ascending: true,
          ),
        )),
        ['bravo', 'Charlie', 'Alpha'],
      );
    });

    test('ties break on creation date, newest first, deterministically', () {
      final tied = [
        _row(name: 'Old', created: DateTime.utc(2026, 1, 1), users: 3),
        _row(name: 'New', created: DateTime.utc(2026, 5, 1), users: 3),
      ];
      const sort = AdminCompaniesSort(
        column: AdminCompanySortColumn.userCount,
        ascending: true,
      );
      expect(_names(AdminCompaniesQuery.sorted(tied, sort)), ['New', 'Old']);
      expect(_names(AdminCompaniesQuery.sorted(tied.reversed.toList(), sort)),
          ['New', 'Old']);
    });

    test('does not mutate the input list', () {
      final input = [...rows];
      AdminCompaniesQuery.sorted(
        input,
        const AdminCompaniesSort(
          column: AdminCompanySortColumn.name,
          ascending: true,
        ),
      );
      expect(_names(input), ['Alpha', 'bravo', 'Charlie']);
    });
  });

  group('AdminCompaniesSort.toggled', () {
    test('re-tapping the active column flips direction', () {
      final flipped = AdminCompaniesSort.initial
          .toggled(AdminCompanySortColumn.creationDate);
      expect(flipped.column, AdminCompanySortColumn.creationDate);
      expect(flipped.ascending, isTrue);
    });

    test('a new column adopts its own natural direction', () {
      final byName =
          AdminCompaniesSort.initial.toggled(AdminCompanySortColumn.name);
      expect(byName.ascending, isTrue, reason: 'text reads A->Z');

      final byUsers =
          AdminCompaniesSort.initial.toggled(AdminCompanySortColumn.userCount);
      expect(byUsers.ascending, isFalse, reason: 'counts open at the big end');
    });
  });

  test('apply filters before sorting', () {
    final result = AdminCompaniesQuery.apply(
      rows,
      search: 'a',
      sort: const AdminCompaniesSort(
        column: AdminCompanySortColumn.name,
        ascending: true,
      ),
      showInactive: true,
    );
    expect(_names(result), ['Alpha', 'bravo', 'Charlie']);

    final narrowed = AdminCompaniesQuery.apply(
      rows,
      search: 'l',
      sort: const AdminCompaniesSort(
        column: AdminCompanySortColumn.name,
        ascending: false,
      ),
      showInactive: true,
    );
    expect(_names(narrowed), ['Charlie', 'Alpha']);
  });

  group('deactivated companies (FS-1001)', () {
    test('are hidden by default', () {
      final visible = AdminCompaniesQuery.filterByActive(rows, false);

      expect(
        visible.every((row) => row.isActive),
        isTrue,
        reason:
            'the list is a support tool - a company nobody can log into is not '
            'the one on the phone, so it is out of the way unless asked for',
      );
    });

    test('are included when asked for', () {
      final all = AdminCompaniesQuery.filterByActive(rows, true);

      expect(
        all.length,
        rows.length,
        reason: 'ticking the box must reveal every company, not merely more',
      );
    });

    test('apply hides them before searching and sorting', () {
      final result = AdminCompaniesQuery.apply(
        rows,
        search: '',
        sort: const AdminCompaniesSort(
          column: AdminCompanySortColumn.name,
          ascending: true,
        ),
        showInactive: false,
      );

      expect(
        result.every((row) => row.isActive),
        isTrue,
        reason:
            'the deactivated filter is part of apply, so every caller gets it '
            'without having to remember a second call',
      );
    });
  });
}
