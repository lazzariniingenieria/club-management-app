import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/app_test_harness.dart';

void main() {
  GoRouter routerUnderTest() => di.sl<AppRouter>().router;

  String currentLocation() =>
      routerUnderTest().routerDelegate.currentConfiguration.uri.path;

  Future<void> navigateTo(WidgetTester tester, String location) async {
    routerUnderTest().go(location);
    await settleSession(tester);
  }

  group('without a session', () {
    testWidgets('a protected route redirects to the login screen', (
      tester,
    ) async {
      await bootApp(tester);

      expect(currentLocation(), AppRoutes.login);

      await navigateTo(tester, AppRoutes.adminHome);
      expect(currentLocation(), AppRoutes.login);
    });
  });

  group('member', () {
    testWidgets('lands on the surface-pending screen, not on a shell', (
      tester,
    ) async {
      await bootApp(tester, signedInAs: UserRole.member);

      expect(currentLocation(), AppRoutes.memberSurfacePending);
      expect(find.text(AppStrings.memberSurfacePendingTitle), findsOneWidget);
    });

    testWidgets('cannot reach the admin surface', (tester) async {
      await bootApp(tester, signedInAs: UserRole.member);

      await navigateTo(tester, AppRoutes.adminHome);
      expect(currentLocation(), AppRoutes.memberSurfacePending);

      await navigateTo(tester, AppRoutes.adminMembers);
      expect(currentLocation(), AppRoutes.memberSurfacePending);
    });
  });

  group('admin', () {
    testWidgets('lands on the admin home and shows only the working tabs', (
      tester,
    ) async {
      await bootApp(tester, signedInAs: UserRole.admin);

      expect(currentLocation(), AppRoutes.adminHome);

      for (final tab in const [
        AppStrings.adminTabHome,
        AppStrings.adminTabPayments,
        AppStrings.adminTabProfile,
      ]) {
        expect(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(tab),
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('has no placeholder tab for the agenda until E9', (
      tester,
    ) async {
      await bootApp(tester, signedInAs: UserRole.admin);

      final navigationBar =
          tester.widget<NavigationBar>(find.byType(NavigationBar));

      expect(navigationBar.destinations, hasLength(3));
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Reservas'),
        ),
        findsNothing,
      );
    });

    testWidgets('reaches the admin push routes', (tester) async {
      await bootApp(tester, signedInAs: UserRole.admin);

      await navigateTo(tester, AppRoutes.adminMembers);
      expect(currentLocation(), AppRoutes.adminMembers);

      await navigateTo(tester, AppRoutes.adminCourts);
      expect(currentLocation(), AppRoutes.adminCourts);
    });

    testWidgets('is pushed out of the super-admin route', (tester) async {
      await bootApp(tester, signedInAs: UserRole.admin);

      await navigateTo(tester, AppRoutes.adminAdmins);
      expect(currentLocation(), AppRoutes.adminHome);
    });

    testWidgets('cannot go back to the login screen while signed in', (
      tester,
    ) async {
      await bootApp(tester, signedInAs: UserRole.admin);

      await navigateTo(tester, AppRoutes.login);
      expect(currentLocation(), AppRoutes.adminHome);
    });
  });

  group('super admin', () {
    testWidgets('shares the admin shell', (tester) async {
      await bootApp(tester, signedInAs: UserRole.superAdmin);

      expect(currentLocation(), AppRoutes.adminHome);
      expect(find.text(AppStrings.roleBadgeSuperAdmin), findsOneWidget);
    });

    testWidgets('reaches the admin management route', (tester) async {
      await bootApp(tester, signedInAs: UserRole.superAdmin);

      await navigateTo(tester, AppRoutes.adminAdmins);
      expect(currentLocation(), AppRoutes.adminAdmins);
    });
  });
}
