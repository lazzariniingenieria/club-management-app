import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/features/admin/presentation/widgets/reports_access_card.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/presentation/formatting/payment_formats.dart';
import 'package:club_management_app/features/reports/presentation/widgets/collection_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

void main() {
  final currentMonth = BillingMonth.of(DateTime.now());

  Future<void> openMetrics(WidgetTester tester) async {
    await bootApp(tester, signedInAs: UserRole.admin);
    await tester.tap(find.byType(ReportsAccessCard));
    await tester.pumpAndSettle();
  }

  testWidgets('opens from the home on the current month', (tester) async {
    await openMetrics(tester);

    expect(find.text(AppStrings.metricsTitle), findsWidgets);
    expect(find.text(PaymentFormats.monthTitle(currentMonth)), findsOneWidget);
    for (final label in [
      AppStrings.metricsCollected,
      AppStrings.metricsFees,
      AppStrings.metricsNewMembers,
      AppStrings.metricsOverdueToday,
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('does not go past the current month', (tester) async {
    await openMetrics(tester);

    final next = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
    );
    expect(next.onPressed, isNull);
  });

  testWidgets('goes back a month with the arrow or a tap on its bar', (
    tester,
  ) async {
    await openMetrics(tester);
    final previous = currentMonth.previous;

    await tester.tap(find.byTooltip(AppStrings.metricsPreviousMonth));
    await tester.pumpAndSettle();
    expect(find.text(PaymentFormats.monthTitle(previous)), findsOneWidget);

    await tester.ensureVisible(find.byType(CollectionChart));
    await tester.tap(
      find.descendant(
        of: find.byType(CollectionChart),
        matching: find.text(PaymentFormats.monthAbbreviation(
          previous.previous.month,
        )),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 800));
    await tester.pumpAndSettle();

    expect(
      find.text(PaymentFormats.monthTitle(previous.previous)),
      findsOneWidget,
    );
  });

  testWidgets('the chart always shows the last six months, whatever is picked',
      (tester) async {
    await openMetrics(tester);
    var oldest = currentMonth;
    for (var step = 0; step < 5; step++) {
      oldest = oldest.previous;
    }
    Finder barOf(BillingMonth month) => find.descendant(
          of: find.byType(CollectionChart),
          matching: find.text(PaymentFormats.monthAbbreviation(month.month)),
        );

    await tester.ensureVisible(find.byType(CollectionChart));
    await tester.tap(barOf(oldest));
    await tester.pumpAndSettle();

    expect(barOf(currentMonth), findsOneWidget);
    expect(barOf(oldest.previous), findsNothing);

    await tester.tap(barOf(currentMonth));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 800));
    await tester.pumpAndSettle();
    expect(find.text(PaymentFormats.monthTitle(currentMonth)), findsOneWidget);
  });
}
