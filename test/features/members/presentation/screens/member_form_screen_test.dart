import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/members/data/datasources/member_fake_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/app_test_harness.dart';

void main() {
  final seededMember = MemberFakeDataSource.roster.first;

  Finder chip(String label, int count) =>
      find.text(AppStrings.withCount(label, count));

  Future<void> openPaymentsTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(AppStrings.adminTabPayments),
      ),
    );
    await settleSession(tester);
  }

  Future<void> bootRoster(WidgetTester tester) async {
    await bootApp(tester, signedInAs: UserRole.admin);
    await openPaymentsTab(tester);
  }

  Future<void> openCreationForm(WidgetTester tester) async {
    await bootRoster(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  Future<void> openEditionForm(WidgetTester tester) async {
    await bootRoster(tester);
    await tester.enterText(find.byType(TextField).first, seededMember.dni);
    await settleSession(tester);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
  }

  Future<void> fillIdentity(
    WidgetTester tester, {
    required String dni,
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ana');
    await tester.enterText(fields.at(1), 'Álvarez');
    await tester.enterText(fields.at(2), dni);
  }

  group('creating a member', () {
    testWidgets('the blue action opens an empty form', (tester) async {
      await openCreationForm(tester);

      expect(find.text(AppStrings.memberFormCreateTitle), findsWidgets);
      expect(find.byType(TextFormField), findsNWidgets(5));
      expect(find.text(AppStrings.memberFormSaveCreation), findsOneWidget);
    });

    testWidgets('an empty form explains what is missing instead of saving', (
      tester,
    ) async {
      await openCreationForm(tester);

      await tester.tap(find.text(AppStrings.memberFormSaveCreation));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormRequiredField), findsNWidgets(3));
      expect(find.text(AppStrings.memberFormCreateTitle), findsWidgets);
    });

    testWidgets('a dni with dots is rejected before reaching the API', (
      tester,
    ) async {
      await openCreationForm(tester);

      await fillIdentity(tester, dni: '30.111.222');
      await tester.tap(find.text(AppStrings.memberFormSaveCreation));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormDniOnlyDigits), findsOneWidget);
    });

    testWidgets('a valid form adds the member to the roster', (tester) async {
      await openCreationForm(tester);

      await fillIdentity(tester, dni: '45999888');
      await tester.tap(find.text(AppStrings.memberFormSaveCreation));
      await tester.pumpAndSettle();

      expect(
        chip(
          AppStrings.adminPaymentsFilterAll,
          MemberFakeDataSource.totalMembers + 1,
        ),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('a dni the club already uses is shown on the field', (
      tester,
    ) async {
      await openCreationForm(tester);

      await fillIdentity(tester, dni: seededMember.dni);
      await tester.tap(find.text(AppStrings.memberFormSaveCreation));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormDniTaken), findsOneWidget);
      expect(find.text(AppStrings.memberFormSaveCreation), findsOneWidget);
    });

    testWidgets('leaving with something typed asks before discarding it', (
      tester,
    ) async {
      await openCreationForm(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Ana');
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormDiscardTitle), findsOneWidget);

      await tester.tap(find.text(AppStrings.memberFormKeepEditingAction));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormSaveCreation), findsOneWidget);
    });
  });

  group('editing a member', () {
    testWidgets('the pencil opens the form with the member already loaded', (
      tester,
    ) async {
      await openEditionForm(tester);

      expect(find.text(AppStrings.memberFormEditTitle), findsWidgets);
      expect(find.text(seededMember.firstName), findsOneWidget);
      expect(find.text(seededMember.dni), findsOneWidget);
      expect(find.text(AppStrings.memberFormSaveEdition), findsOneWidget);
    });

    testWidgets('the logical delete names the member before running', (
      tester,
    ) async {
      await openEditionForm(tester);

      await tester.tap(find.text(AppStrings.memberDeactivateAction));
      await tester.pumpAndSettle();

      expect(
        find.text(
          AppStrings.memberDeactivateConfirmTitle(seededMember.fullName),
        ),
        findsOneWidget,
      );
    });

    testWidgets('confirming the logical delete returns to the roster', (
      tester,
    ) async {
      await openEditionForm(tester);

      await tester.tap(find.text(AppStrings.memberDeactivateAction));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(AppStrings.memberDeactivateAction),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormSaveEdition), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
    });
  });
}
