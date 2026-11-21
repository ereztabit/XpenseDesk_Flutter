// FS-1026 aesthetics round - the scan images stay side by side (two equal
// columns at 800px, a sideways-scrolling row at phone width - never stacked),
// and each image has its Download and Open buttons; a running download shows busy.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations.dart';
import 'package:xpensedesk_flutter/models/admin_ai_scan_review.dart';
import 'package:xpensedesk_flutter/widgets/admin/receipt_ai/ai_scan_image_column.dart';
import 'package:xpensedesk_flutter/widgets/admin/receipt_ai/ai_scan_images_view.dart';
import 'package:xpensedesk_flutter/widgets/app_button.dart';

const _base = 'https://xd.blob.core.windows.net/receipt-dumps/c1/receipt_1';

AdminAiScanReview _review({bool pdf = false}) => AdminAiScanReview(
  expenseId: 'e1',
  companyId: 'c1',
  companyName: 'Harbor',
  isClosed: false,
  isForeign: false,
  modelResults: const [],
  expense: const AdminAiScanValues(),
  originalImageUrl: pdf ? '${_base}_upload.pdf' : '${_base}_upload.jpg',
  processedImageUrl: '${_base}_processed.jpg',
  scanRecord: pdf
      ? {
          'steps': [
            {
              'step': 'convert-to-image',
              'output': {'url': '${_base}_converted.png'},
            },
          ],
        }
      : null,
);

Future<List<(String, String)>> _pump(
  WidgetTester tester,
  double width, {
  bool pdf = false,
  Future<void> Function(String url, String name)? onDownload,
}) async {
  final downloads = <(String, String)>[];
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          child: AiScanImagesView(
            review: _review(pdf: pdf),
            onDownload: onDownload ?? (url, name) async => downloads.add((url, name)),
            onOpen: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return downloads;
}

void main() {
  testWidgets('side by side at 800px: two equal columns on one row', (tester) async {
    await _pump(tester, 800);

    final columns = find.byType(AiScanImageColumn);
    expect(columns, findsNWidgets(2));
    final a = tester.getRect(columns.at(0));
    final b = tester.getRect(columns.at(1));
    expect(a.top, b.top);
    expect(a.width, closeTo(b.width, 0.5));
    expect(a.right <= b.left || b.right <= a.left, isTrue);
  });

  testWidgets('at phone width the two images stay on one row (scrolling)', (tester) async {
    await _pump(tester, 375);

    final columns = find.byType(AiScanImageColumn);
    expect(tester.getRect(columns.at(0)).top, tester.getRect(columns.at(1)).top);
    expect(tester.getRect(columns.at(0)).width, greaterThanOrEqualTo(AiScanImagesView.minColumnWidth));
  });

  testWidgets('each image has Download and Open buttons that save the file', (tester) async {
    final downloads = await _pump(tester, 1100, pdf: true);

    expect(find.widgetWithText(AppButton, 'Download original'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Download processed'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Open in new tab'), findsNWidgets(2));

    await tester.tap(find.widgetWithText(AppButton, 'Download original'));
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, 'Download processed'));
    // A PDF upload downloads the PDF itself, not the page render it previews.
    expect(downloads, [
      ('${_base}_upload.pdf', 'receipt_1_upload.pdf'),
      ('${_base}_processed.jpg', 'receipt_1_processed.jpg'),
    ]);
  });

  testWidgets('a running download shows busy on its button; the other waits', (tester) async {
    final pending = Completer<void>();
    await _pump(tester, 1100, onDownload: (_, _) => pending.future);

    // A busy button shows a spinner instead of its label - find it by label.
    AppButton button(String label) =>
        tester.widget<AppButton>(find.byWidgetPredicate((w) => w is AppButton && w.label == label));
    await tester.tap(find.widgetWithText(AppButton, 'Download original'));
    await tester.pump();
    expect(button('Download original').isLoading, isTrue);
    expect(button('Download processed').onPressed, isNull);

    pending.complete();
    await tester.pump();
    expect(button('Download original').isLoading, isFalse);
    expect(button('Download processed').onPressed, isNotNull);
  });
}
