import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/admin/presentation/widgets/quick_access_card.dart';
import 'package:club_management_app/features/admin/presentation/widgets/summary_count_card.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

void main() {
  String currentLocation() =>
      di.sl<AppRouter>().router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('an admin lands on the home with the club summary', (
    tester,
  ) async {
    await bootApp(tester, signedInAs: UserRole.admin);

    expect(currentLocation(), AppRoutes.adminHome);
    expect(find.text('230'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
  });

  testWidgets('the counters open the member list', (tester) async {
    await bootApp(tester, signedInAs: UserRole.admin);

    await tester.tap(find.byType(SummaryCountCard).first);
    await settleSession(tester);

    expect(currentLocation(), AppRoutes.adminMembers);
    expect(find.text(AppStrings.adminMembersTitle), findsWidgets);
  });

  testWidgets('the quick access card opens court management', (tester) async {
    await bootApp(tester, signedInAs: UserRole.admin);

    await tester.tap(find.byType(QuickAccessCard).last);
    await settleSession(tester);

    expect(currentLocation(), AppRoutes.adminCourts);
  });

  testWidgets('a super admin sees the same home surface', (tester) async {
    await bootApp(tester, signedInAs: UserRole.superAdmin);

    expect(currentLocation(), AppRoutes.adminHome);
    expect(find.text(AppStrings.roleBadgeSuperAdmin), findsOneWidget);
    expect(find.text('230'), findsOneWidget);
  });
}
