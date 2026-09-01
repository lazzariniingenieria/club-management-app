import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_test_harness.dart';

void main() {
  String currentLocation() =>
      di.sl<AppRouter>().router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('boots into the login screen when there is no session', (
    tester,
  ) async {
    await bootApp(tester);

    expect(currentLocation(), AppRoutes.login);
    expect(find.text(AppStrings.loginWelcomeTitle), findsOneWidget);
  });

  testWidgets('boots straight into the admin shell with a stored session', (
    tester,
  ) async {
    await bootApp(tester, signedInAs: UserRole.admin);

    expect(currentLocation(), AppRoutes.adminHome);
    expect(find.text(AppStrings.roleBadgeAdmin), findsOneWidget);
  });
}
