import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/admins/data/datasources/admin_fake_data_source.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

void main() {
  late AdminFakeDataSource admins;

  Future<void> openAdmins(WidgetTester tester) async {
    admins = AdminFakeDataSource(latency: Duration.zero);
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
}
