import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/constants/storage_keys.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/auth/data/datasources/auth_fake_data_source.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';
import '../../../helpers/in_memory_secure_storage.dart';

void main() {
  String currentLocation() =>
      di.sl<AppRouter>().router.routerDelegate.currentConfiguration.uri.path;

  Future<void> signIn(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await tester.enterText(find.byType(TextFormField).first, email);
    await tester.enterText(find.byType(TextFormField).last, password);
    await tester.tap(find.text(AppStrings.loginSubmitButton));
    await settleSession(tester);
  }

  testWidgets('an admin signs in against the fakes and lands on the shell', (
    tester,
  ) async {
    final storage = await bootApp(tester);

    await signIn(
      tester,
      email: 'admin@club.com',
      password: AuthFakeDataSource.sharedPassword,
    );

    expect(currentLocation(), AppRoutes.adminHome);
    expect(storage.values[StorageKeys.accessToken], isNotNull);
    expect(storage.values[StorageKeys.currentUser], contains('ADMIN'));
  });

  testWidgets('a super admin signs in and gets the super admin badge', (
    tester,
  ) async {
    await bootApp(tester);

    await signIn(
      tester,
      email: 'super@club.com',
      password: AuthFakeDataSource.sharedPassword,
    );

    expect(currentLocation(), AppRoutes.adminHome);
    expect(find.text(AppStrings.roleBadgeSuperAdmin), findsOneWidget);
  });

  testWidgets('a member signs in and is told the surface is being prepared', (
    tester,
  ) async {
    await bootApp(tester);

    await signIn(
      tester,
      email: 'socio@club.com',
      password: AuthFakeDataSource.sharedPassword,
    );

    expect(currentLocation(), AppRoutes.memberSurfacePending);
    expect(find.text(AppStrings.memberSurfacePendingMessage), findsOneWidget);
  });

  testWidgets('wrong credentials keep the user on the login screen', (
    tester,
  ) async {
    final storage = await bootApp(tester);

    await signIn(
      tester,
      email: 'admin@club.com',
      password: 'not-the-password',
    );

    expect(currentLocation(), AppRoutes.login);
    expect(storage.values[StorageKeys.accessToken], isNull);
  });

  testWidgets('logging out returns to the login screen and clears the session',
      (tester) async {
    final InMemorySecureStorage storage = await bootApp(
      tester,
      signedInAs: UserRole.admin,
    );

    di.sl<AppRouter>().router.go(AppRoutes.adminProfile);
    await settleSession(tester);

    await tester.tap(find.text(AppStrings.logoutAction));
    await settleSession(tester);
    await tester.tap(find.widgetWithText(TextButton, AppStrings.logoutAction));
    await settleSession(tester);

    expect(currentLocation(), AppRoutes.login);
    expect(storage.values, isEmpty);
  });
}
