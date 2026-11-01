import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/admins/data/datasources/admin_fake_data_source.dart';
import 'package:club_management_app/features/admins/data/datasources/admin_remote_data_source.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/shared/widgets/app_secondary_button.dart';
import 'package:club_management_app/shared/widgets/logout_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/app_test_harness.dart';

void main() {
  Future<void> openProfile(
    WidgetTester tester,
    UserRole role, {
    AdminRemoteDataSource? adminSource,
  }) async {
    await bootApp(tester, signedInAs: role, adminSource: adminSource);
    di.sl<AppRouter>().router.go(AppRoutes.adminProfile);
    await tester.pumpAndSettle();
  }

  Future<void> tapChangePassword(WidgetTester tester) async {
    final link = find.text(AppStrings.profileChangePassword);
    await tester.ensureVisible(link);
    await tester.pumpAndSettle();
    await tester.tap(link);
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

  testWidgets('changing the password sits under Cerrar sesión, as wide', (
    tester,
  ) async {
    await openProfile(tester, UserRole.admin);
    final link = find.widgetWithText(TextButton, AppStrings.profileChangePassword);
    await tester.ensureVisible(link);
    await tester.pumpAndSettle();

    final logout = tester.getRect(find.byType(LogoutButton));
    final password = tester.getRect(link);
    expect(password.top, greaterThanOrEqualTo(logout.bottom));
    expect(password.width, logout.width);
  });

  testWidgets('the super admin changes their own password', (tester) async {
    await openProfile(tester, UserRole.superAdmin);

    await tapChangePassword(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'nueva-clave-1');
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.passwordChangeAction),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.passwordChangedTitle), findsOneWidget);
  });

  testWidgets('the password sheet cannot be closed while the change is saving',
      (tester) async {
    await openProfile(
      tester,
      UserRole.admin,
      adminSource: AdminFakeDataSource(latency: const Duration(seconds: 1)),
    );

    await tapChangePassword(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'nueva-clave-1');
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.passwordChangeAction),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final cancel = tester.widget<AppSecondaryButton>(
      find.widgetWithText(AppSecondaryButton, AppStrings.cancelAction),
    );
    expect(cancel.onPressed, isNull);

    await tester.tapAt(const Offset(10, 10));
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(AppStrings.passwordChangedTitle), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text(AppStrings.passwordChangedTitle), findsOneWidget);
  });

  testWidgets('a short new password is explained in the field', (
    tester,
  ) async {
    await openProfile(tester, UserRole.admin);

    await tapChangePassword(tester);
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

      await tapChangePassword(tester);
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
