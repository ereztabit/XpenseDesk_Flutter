// PC-5 (FS-1016): the downloaded file's name and the error captions.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations.dart';
import 'package:xpensedesk_flutter/utils/sheet_export_copy_utils.dart';
import 'package:xpensedesk_flutter/utils/sheet_export_utils.dart';

final en = lookupAppLocalizations(const Locale('en'));
final he = lookupAppLocalizations(const Locale('he'));

void main() {
  group('sheetExportFileName', () {
    test('reads filename*= first (what ASP.NET sends with both forms)', () {
      expect(
        sheetExportFileName(
          "attachment; filename=Monthly_2026-11_a3f9c1.pdf; filename*=UTF-8''Monthly_2026-11_a3f9c1.pdf",
          SheetExportFormat.pdf,
        ),
        'Monthly_2026-11_a3f9c1.pdf',
      );
    });

    test('decodes an escaped filename*', () {
      expect(
        sheetExportFileName("attachment; filename*=UTF-8''Budget%201002.xlsx", SheetExportFormat.excel),
        'Budget 1002.xlsx',
      );
    });

    test('falls back to a quoted filename=', () {
      expect(
        sheetExportFileName('attachment; filename="Budget_1002.xlsx"', SheetExportFormat.excel),
        'Budget_1002.xlsx',
      );
    });

    test('missing header -> sheet-export.<ext> per format', () {
      expect(sheetExportFileName(null, SheetExportFormat.pdf), 'sheet-export.pdf');
      expect(sheetExportFileName('', SheetExportFormat.excel), 'sheet-export.xlsx');
      expect(sheetExportFileName('attachment', SheetExportFormat.excel), 'sheet-export.xlsx');
    });

    test('drops any path part', () {
      expect(
        sheetExportFileName('attachment; filename="../../x/Budget_1.pdf"', SheetExportFormat.pdf),
        'Budget_1.pdf',
      );
    });
  });

  group('SheetExportFormat', () {
    test('api values and MIME types', () {
      expect(SheetExportFormat.pdf.apiValue, 'pdf');
      expect(SheetExportFormat.excel.apiValue, 'excel');
      expect(SheetExportFormat.pdf.mimeType, 'application/pdf');
      expect(
        SheetExportFormat.excel.mimeType,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    });
  });

  group('sheetExportErrorText', () {
    final cases = {
      'SheetExportNotApproved': (AppLocalizations l) => l.sheetExportErrorNotApproved,
      'SheetExportTooLarge': (AppLocalizations l) => l.sheetExportErrorTooLarge,
      'SheetExportBusy': (AppLocalizations l) => l.sheetExportErrorBusy,
      'SheetExportFailed': (AppLocalizations l) => l.sheetExportErrorFailed,
      'ExpenseSheetNotFound': (AppLocalizations l) => l.sheetExportErrorNotFound,
    };

    for (final l10n in [en, he]) {
      test('every code has its own caption (${l10n.localeName})', () {
        cases.forEach((code, caption) {
          expect(sheetExportErrorText(l10n, code), caption(l10n));
          expect(caption(l10n), isNot(l10n.genericErrorRetry));
        });
      });

      test('unknown or no code -> generic retry (${l10n.localeName})', () {
        expect(sheetExportErrorText(l10n, 'SomethingElse'), l10n.genericErrorRetry);
        expect(sheetExportErrorText(l10n, null), l10n.genericErrorRetry);
      });
    }
  });
}
