// FS-1025 #17: a blocked "Submit for approval" looks disabled, never submits,
// and a tap on it asks the Needs action card to shake.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations.dart';
import 'package:xpensedesk_flutter/providers/budget_shake_provider.dart';
import 'package:xpensedesk_flutter/widgets/budgets/budget_submit_button.dart';

Future<ProviderContainer> _pump(WidgetTester tester, {required bool blocked, required VoidCallback onPressed}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  // Keep the family alive, as the Needs action card does by watching it.
  container.listen(budgetNeedsActionShakeProvider('b1'), (_, _) {});
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BudgetSubmitButton(
          budgetId: 'b1',
          amountText: '₪50.00',
          isBusy: false,
          blocked: blocked,
          onPressed: onPressed,
        ),
      ),
    ),
  ));
  return container;
}

void main() {
  testWidgets('blocked: looks disabled, does not submit, shakes the card', (tester) async {
    var submitted = 0;
    final container = await _pump(tester, blocked: true, onPressed: () => submitted++);

    final button = tester.widget<ElevatedButton>(find.byWidgetPredicate((w) => w is ElevatedButton));
    expect(button.onPressed, isNull, reason: 'a blocked Submit must read as disabled');

    await tester.tap(find.byType(BudgetSubmitButton));
    await tester.pump();
    expect(submitted, 0);
    expect(container.read(budgetNeedsActionShakeProvider('b1')), 1);
  });

  testWidgets('not blocked: submits, no shake', (tester) async {
    var submitted = 0;
    final container = await _pump(tester, blocked: false, onPressed: () => submitted++);

    await tester.tap(find.byType(BudgetSubmitButton));
    await tester.pump();
    expect(submitted, 1);
    expect(container.read(budgetNeedsActionShakeProvider('b1')), 0);
  });
}
