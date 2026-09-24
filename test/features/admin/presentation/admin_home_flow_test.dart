import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/admin/data/datasources/admin_summary_remote_data_source.dart';
import 'package:club_management_app/features/admin/data/models/admin_summary_model.dart';
import 'package:club_management_app/features/admin/presentation/widgets/quick_access_card.dart';
import 'package:club_management_app/features/admin/presentation/widgets/summary_count_card.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

class GrowingClubDataSource implements AdminSummaryRemoteDataSource {
  int calls = 0;

  @override
  Future<AdminSummaryModel> fetchSummary() async {
    calls++;
    return AdminSummaryModel(activeMembers: 229 + calls, overdueMembers: 25);
  }
}

void main() {
  String currentLocation() => di
      .sl<AppRouter>()
      .router
      .routerDelegate
      .currentConfiguration
      .last
      .matchedLocation;

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await settleSession(tester);
  }

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

  testWidgets('coming back from the member list shows fresh numbers', (
    tester,
  ) async {
    final dataSource = GrowingClubDataSource();
    await bootApp(
      tester,
      signedInAs: UserRole.admin,
      adminSummarySource: dataSource,
    );

    await tester.tap(find.byType(SummaryCountCard).first);
    await settleSession(tester);
    di.sl<AppRouter>().router.pop();
    await settleSession(tester);

    expect(currentLocation(), AppRoutes.adminHome);
    expect(dataSource.calls, 2);
    expect(find.text('231'), findsOneWidget);
  });

  testWidgets('switching back to the home tab shows fresh numbers', (
    tester,
  ) async {
    final dataSource = GrowingClubDataSource();
    await bootApp(
      tester,
      signedInAs: UserRole.admin,
      adminSummarySource: dataSource,
    );

    await tapTab(tester, AppStrings.adminTabPayments);
    await tapTab(tester, AppStrings.adminTabHome);

    expect(dataSource.calls, 2);
    expect(find.text('231'), findsOneWidget);
  });
}
