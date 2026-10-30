import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/app_test_harness.dart';

void main() {
  Future<void> openProfile(WidgetTester tester, UserRole role) async {
    await bootApp(tester, signedInAs: role);
    di.sl<AppRouter>().router.go(AppRoutes.adminProfile);
    await tester.pumpAndSettle();
  }

  testWidgets('an admin edits the club fee but does not manage admins', (
    tester,
  ) async {
    await openProfile(tester, UserRole.admin);

    expect(find.text(AppStrings.profileRoleAdmin), findsOneWidget);
    expect(find.text(r'$15.000'), findsOneWidget);
    expect(find.byTooltip(AppStrings.profileEditMonthlyFee), findsOneWidget);
    expect(find.text(AppStrings.adminProfileManageAdmins), findsNothing);
  });

  testWidgets('the super admin edits the fee and reaches the admins list', (
    tester,
  ) async {
    await openProfile(tester, UserRole.superAdmin);

    expect(find.text(AppStrings.profileRoleSuperAdmin), findsOneWidget);
    expect(find.text(AppStrings.adminProfileManageAdmins), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.profileEditMonthlyFee));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '16000');
    await tester.tap(find.text(AppStrings.saveAction));
    await tester.pumpAndSettle();

    expect(find.text(r'$16.000'), findsOneWidget);
    expect(find.text(AppStrings.feeSaved), findsOneWidget);
  });

  testWidgets('the super admin changes their own password', (tester) async {
    await openProfile(tester, UserRole.superAdmin);

    await tester.tap(find.text(AppStrings.profileChangePassword));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'nueva-clave-1');
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.passwordChangeAction),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.passwordChangedTitle), findsOneWidget);
  });

  testWidgets('a short new password is explained in the field', (
    tester,
  ) async {
    await openProfile(tester, UserRole.admin);

    await tester.tap(find.text(AppStrings.profileChangePassword));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.widgetWithText(ElevatedButton, AppStrings.passwordChangeAction));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.passwordTooShort), findsOneWidget);
  });

  testWidgets(
    'a password over 72 bytes because of its accents is explained in the field',
    (tester) async {
      await openProfile(tester, UserRole.admin);

      await tester.tap(find.text(AppStrings.profileChangePassword));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ñ' * 40);
      await tester.tap(
        find.widgetWithText(ElevatedButton, AppStrings.passwordChangeAction),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.passwordTooLong), findsOneWidget);
      expect(find.text(AppStrings.passwordChangedTitle), findsNothing);
    },
  );
}
