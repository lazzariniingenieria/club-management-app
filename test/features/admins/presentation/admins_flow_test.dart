import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'dart:async';

import 'package:club_management_app/features/admins/data/datasources/admin_fake_data_source.dart';
import 'package:club_management_app/features/admins/domain/entities/admin_draft.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

class HeldUpdateSource extends AdminFakeDataSource {
  HeldUpdateSource() : super(latency: Duration.zero);

  final release = Completer<void>();

  @override
  Future<void> updateAdmin(int adminId, AdminDraft draft) async {
    await release.future;

    return super.updateAdmin(adminId, draft);
  }
}

void main() {
  late AdminFakeDataSource admins;

  Future<void> openAdmins(WidgetTester tester,
      {AdminFakeDataSource? source}) async {
    admins = source ?? AdminFakeDataSource(latency: Duration.zero);
    await bootApp(tester, signedInAs: UserRole.superAdmin, adminSource: admins);
    di.sl<AppRouter>().router.go(AppRoutes.adminProfile);
    await tester.pumpAndSettle();
    di.sl<AppRouter>().router.push(AppRoutes.adminAdmins);
    await tester.pumpAndSettle();
  }

  testWidgets('lists admins, the deactivated ones with a reactivate action', (
    tester,
  ) async {
    await openAdmins(tester);

    expect(find.text('Juan Álvarez'), findsOneWidget);
    expect(find.text(AppStrings.adminReactivateShort), findsOneWidget);
  });

  testWidgets('creates an admin with an initial password', (tester) async {
    await openAdmins(tester);

    await tester.tap(find.text(AppStrings.adminsNew));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.adminFormDni),
      '40111222',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.adminFormPassword),
      's3cr3t123',
    );
    await tester.tap(find.text(AppStrings.adminFormCreate));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.adminFormCreated), findsOneWidget);
    final stored = await tester.runAsync(admins.fetchAdmins);
    expect(stored!.map((admin) => admin.dni), contains('40111222'));
  });

  testWidgets('a short initial password is explained in the field', (
    tester,
  ) async {
    await openAdmins(tester);

    await tester.tap(find.text(AppStrings.adminsNew));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.adminFormDni),
      '40111222',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.adminFormPassword),
      '123',
    );
    await tester.tap(find.text(AppStrings.adminFormCreate));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.passwordTooShort), findsOneWidget);
  });

  testWidgets('a blank initial password is explained and never sent', (
    tester,
  ) async {
    await openAdmins(tester);
    final before = (await tester.runAsync(admins.fetchAdmins))!.length;

    await tester.tap(find.text(AppStrings.adminsNew));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.adminFormDni),
      '40111222',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.adminFormPassword),
      '        ',
    );
    await tester.tap(find.text(AppStrings.adminFormCreate));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.passwordBlank), findsOneWidget);
    expect((await tester.runAsync(admins.fetchAdmins))!, hasLength(before));
  });

  testWidgets('an admin still needs a dni, because it is how they sign in', (
    tester,
  ) async {
    await openAdmins(tester);
    final before = (await tester.runAsync(admins.fetchAdmins))!.length;

    await tester.tap(find.text(AppStrings.adminsNew));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.adminFormPassword),
      's3cr3t123',
    );
    await tester.tap(find.text(AppStrings.adminFormCreate));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.memberFormRequiredField), findsOneWidget);
    expect((await tester.runAsync(admins.fetchAdmins))!, hasLength(before));
  });

  testWidgets('a repeated dni is reported without losing the form', (
    tester,
  ) async {
    await openAdmins(tester);

    await tester.tap(find.text(AppStrings.adminsNew));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.adminFormDni),
      '11111111',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.adminFormPassword),
      's3cr3t123',
    );
    await tester.tap(find.text(AppStrings.adminFormCreate));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.adminFormConflict), findsOneWidget);
    expect(find.text('11.111.111'), findsOneWidget);
  });

  group('the account actions of an admin being edited', () {
    ButtonStyleButton buttonWith(WidgetTester tester, String label) =>
        tester.widget<ButtonStyleButton>(
          find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          ),
        );

    testWidgets('are disabled while the form saves', (tester) async {
      final source = HeldUpdateSource();
      await openAdmins(tester, source: source);
      await tester.tap(find.text('Juan Álvarez'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.adminFormEmail),
        'juan@club.com',
      );
      await tester.tap(find.text(AppStrings.adminFormSave));
      await tester.pump();

      expect(
          buttonWith(tester, AppStrings.adminResetPassword).onPressed, isNull);
      expect(buttonWith(tester, AppStrings.adminDeactivate).onPressed, isNull);

      source.release.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('warn that deactivating discards unsaved changes', (
      tester,
    ) async {
      await openAdmins(tester);
      await tester.tap(find.text('Juan Álvarez'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.adminFormEmail),
        'juan@club.com',
      );

      await tester.ensureVisible(find.text(AppStrings.adminDeactivate));
      await tester.tap(find.text(AppStrings.adminDeactivate));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(AppStrings.adminUnsavedChangesLost),
        findsOneWidget,
      );
    });
  });

  group('deactivating an admin', () {
    Future<void> deactivate(WidgetTester tester, String row) async {
      await tester.tap(find.text(row));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(AppStrings.adminDeactivate));
      await tester.tap(find.text(AppStrings.adminDeactivate));
      await tester.pumpAndSettle();
    }

    Future<void> confirm(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(AppStrings.adminDeactivate),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('linked to a member keeps them as a member', (tester) async {
      await openAdmins(tester);

      await deactivate(tester, 'Juan Álvarez');
      expect(
        find.text(AppStrings.adminDeactivateLinkedTitle('Juan Álvarez')),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.adminDeactivateLinkedMessage),
        findsOneWidget,
      );
      await confirm(tester);

      expect(
        find.text(AppStrings.adminKeptAsMember('Juan Álvarez')),
        findsOneWidget,
      );
      expect(find.text('Juan Álvarez'), findsNothing);
    });

    testWidgets('without a member stays listed as inactive', (tester) async {
      await openAdmins(tester);

      await deactivate(tester, AppStrings.memberDni('11.111.111'));
      expect(find.text(AppStrings.adminDeactivateMessage), findsOneWidget);
      await confirm(tester);

      expect(find.text(AppStrings.adminDeactivated), findsOneWidget);
      expect(find.text(AppStrings.adminReactivateShort), findsNWidgets(2));
    });
  });
}
