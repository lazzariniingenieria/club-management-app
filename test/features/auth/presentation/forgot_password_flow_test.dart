import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

void main() {
  String currentLocation() => di
      .sl<AppRouter>()
      .router
      .routerDelegate
      .currentConfiguration
      .last
      .matchedLocation;

  testWidgets('the login explains how to recover a password', (tester) async {
    await bootApp(tester);

    await tester.tap(find.text(AppStrings.loginForgotPassword));
    await tester.pumpAndSettle();

    expect(currentLocation(), AppRoutes.loginForgotPassword);
    expect(find.text(AppStrings.forgotPasswordAskAdmin), findsOneWidget);
    expect(find.text(AppStrings.forgotPasswordMember), findsOneWidget);

    await tester.tap(find.text(AppStrings.forgotPasswordBack));
    await tester.pumpAndSettle();

    expect(currentLocation(), AppRoutes.login);
  });
}
