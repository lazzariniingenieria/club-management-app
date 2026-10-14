import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/members/data/models/member_model.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/payments/data/datasources/payment_fake_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/app_test_harness.dart';
import '../../../../helpers/member_roster_data_source.dart';

void main() {
  final roster = <MemberModel>[
    buildMember(id: 1, firstName: 'Juan', lastName: 'Zárate', daysOverdue: 42),
    buildMember(id: 2, firstName: 'Ana', lastName: 'Álvarez'),
    buildMember(
      id: 3,
      firstName: 'Luis',
      lastName: 'Gómez',
      status: MemberStatus.inactive,
    ),
  ];

  String currentLocation() => di
      .sl<AppRouter>()
      .router
      .routerDelegate
      .currentConfiguration
      .last
      .matchedLocation;

  Future<void> bootClub(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final members = MemberRosterDataSource(roster);
    await bootApp(
      tester,
      signedInAs: UserRole.admin,
      memberSource: members,
      paymentSource: PaymentFakeDataSource(
        members: members,
        latency: Duration.zero,
        clock: () => DateTime(2026, 10, 14),
      ),
    );
  }

  Future<void> openPaymentsTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(AppStrings.adminTabPayments),
      ),
    );
    await settleSession(tester);
  }

  Future<void> reviewAndConfirm(WidgetTester tester, String total) async {
    await tester.tap(
      find.text(AppStrings.registerPaymentReviewWithTotal(total)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.confirmPaymentAction(total)));
    await tester.pumpAndSettle();
  }

  group('from the Pagos tab', () {
    testWidgets('tapping a member opens their ledger', (tester) async {
      await bootClub(tester);
      await openPaymentsTab(tester);

      await tester.tap(find.text('Juan Zárate'));
      await tester.pumpAndSettle();

      expect(currentLocation(), AppRoutes.adminMemberLedger(1));
      expect(find.text(AppStrings.ledgerDaysOverdue(42)), findsOneWidget);
      expect(
        find.text(AppStrings.ledgerLastPaid('agosto 2026')),
        findsOneWidget,
      );
    });

    testWidgets('a payment registered from the ledger shows up in it', (
      tester,
    ) async {
      await bootClub(tester);
      await openPaymentsTab(tester);
      await tester.tap(find.text('Juan Zárate'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.ledgerRegisterAction));
      await tester.pumpAndSettle();
      expect(
        find.text(
          AppStrings.registerPaymentSuggestionAfterLastPaid('septiembre'),
        ),
        findsOneWidget,
      );
      await reviewAndConfirm(tester, r'$15.000');

      expect(currentLocation(), AppRoutes.adminMemberLedger(1));
      expect(
        find.text(
          AppStrings.paymentRegistered('septiembre de 2026', r'$15.000'),
        ),
        findsOneWidget,
      );
      expect(find.text(AppStrings.ledgerNewTag), findsOneWidget);
    });
  });

  group('from the home card', () {
    Future<void> openPicker(WidgetTester tester) async {
      await bootClub(tester);
      await tester.tap(find.text(AppStrings.adminHomeRegisterPaymentAccess));
      await settleSession(tester);
    }

    testWidgets('lists the members who owe first and leaves out inactives', (
      tester,
    ) async {
      await openPicker(tester);

      expect(
        find.text(AppStrings.paymentPickerOverdueSection(1)),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.paymentPickerUpToDateSection(1)),
        findsOneWidget,
      );
      expect(find.text('Luis Gómez'), findsNothing);

      final overdueTop = tester.getTopLeft(find.text('Juan Zárate')).dy;
      final upToDateTop = tester.getTopLeft(find.text('Ana Álvarez')).dy;
      expect(overdueTop, lessThan(upToDateTop));
    });

    testWidgets('finds a member by dni', (tester) async {
      await openPicker(tester);

      await tester.enterText(find.byType(TextField), roster[1].dni);
      await settleSession(tester);

      expect(find.text('Ana Álvarez'), findsOneWidget);
      expect(find.text('Juan Zárate'), findsNothing);
    });

    testWidgets('ends on the ledger of the member that just paid', (
      tester,
    ) async {
      await openPicker(tester);

      await tester.tap(find.text('Ana Álvarez'));
      await tester.pumpAndSettle();
      await reviewAndConfirm(tester, r'$15.000');

      expect(currentLocation(), AppRoutes.adminMemberLedger(2));
      expect(
        find.text(
          AppStrings.paymentRegistered('noviembre de 2026', r'$15.000'),
        ),
        findsOneWidget,
      );

      di.sl<AppRouter>().router.pop();
      await settleSession(tester);
      expect(currentLocation(), AppRoutes.adminHome);
    });
  });
}
