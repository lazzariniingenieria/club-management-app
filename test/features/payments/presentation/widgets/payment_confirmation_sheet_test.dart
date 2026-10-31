import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/domain/entities/member_ledger.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_method.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_precheck.dart';
import 'package:club_management_app/features/payments/presentation/cubit/family_payment.dart';
import 'package:club_management_app/features/payments/presentation/cubit/payment_form.dart';
import 'package:club_management_app/features/payments/presentation/widgets/payment_confirmation_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Member member(int id, String firstName) => Member(
      id: id,
      firstName: firstName,
      lastName: 'Pérez',
      dni: '${30000000 + id}',
      status: MemberStatus.active,
      daysOverdue: 0,
      familyGroupId: 7,
    );

void main() {
  final juan = member(1, 'Juan');
  final ana = member(2, 'Ana');
  final luis = member(3, 'Luis');
  const august = BillingMonth(2026, 8);
  const september = BillingMonth(2026, 9);

  PaymentForm formFor({FamilyPayment? family}) => PaymentForm(
        ledger: MemberLedger(
          member: juan,
          payments: const [],
          familyMembers: [ana, luis],
          memberNames: {1: juan.fullName, 2: ana.fullName, 3: luis.fullName},
        ),
        selectedMonths: {august, september},
        suggestedMonth: august,
        visibleYear: 2026,
        method: PaymentMethod.cash,
        amountCents: 1500000,
        family: family,
      );

  Future<void> pumpSheet(WidgetTester tester, PaymentForm form) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PaymentConfirmationSheet(form: form)),
      ),
    );
  }

  Finder rowOf(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(Row)).first;

  testWidgets('leads with the total and how it is paid', (tester) async {
    await pumpSheet(tester, formFor());

    expect(find.text(r'$30.000'), findsOneWidget);
    expect(
      find.text(
        AppStrings.confirmPaymentSummary(
          AppStrings.feeCount(2),
          AppStrings.paymentMethodCash,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a single member is one row with its months and subtotal', (
    tester,
  ) async {
    await pumpSheet(tester, formFor());

    expect(
      find.descendant(
        of: rowOf('Juan Pérez'),
        matching: find.text('Agosto y septiembre de 2026'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('DNI'), findsNothing);
  });

  testWidgets('a family payment lists each member the same way', (
    tester,
  ) async {
    final family = const FamilyPayment().loaded({
      1: const PaymentPrecheck(isActive: true, paidMonths: {}),
      2: PaymentPrecheck(isActive: true, paidMonths: {august}),
      3: PaymentPrecheck(
        isActive: true,
        paidMonths: {august, september},
      ),
    });
    await pumpSheet(tester, formFor(family: family));

    expect(
      find.descendant(of: rowOf('Juan Pérez'), matching: find.text(r'$30.000')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: rowOf('Ana Pérez'), matching: find.text(r'$15.000')),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: rowOf('Luis Pérez'),
        matching: find.text(AppStrings.confirmPaymentSkipped),
      ),
      findsOneWidget,
    );
    expect(find.text(r'$45.000'), findsOneWidget);
  });
}
