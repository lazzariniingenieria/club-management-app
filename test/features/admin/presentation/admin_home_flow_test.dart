import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/admin/data/datasources/admin_summary_remote_data_source.dart';
import 'package:club_management_app/features/admin/data/models/admin_summary_model.dart';
import 'package:club_management_app/features/admin/presentation/widgets/quick_access_card.dart';
import 'package:club_management_app/features/admin/presentation/widgets/summary_count_card.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/members/data/models/member_model.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/members/domain/entities/member_collection_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';
import '../../../helpers/member_roster_data_source.dart';

class GrowingClubDataSource implements AdminSummaryRemoteDataSource {
  int calls = 0;

  @override
  Future<AdminSummaryModel> fetchSummary() async {
    calls++;
    return AdminSummaryModel(activeMembers: 229 + calls, overdueMembers: 25);
  }
}

void main() {
  final roster = <MemberModel>[
    buildMember(id: 1, firstName: 'Juan', lastName: 'Zárate', daysOverdue: 42),
    buildMember(id: 2, firstName: 'Ana', lastName: 'Álvarez'),
    buildMember(
      id: 3,
      firstName: 'Luis',
      lastName: 'Gómez',
      status: MemberStatus.inactive,
    ),
  ];

  String currentLocation() => di
      .sl<AppRouter>()
      .router
      .routerDelegate
      .currentConfiguration
      .last
      .matchedLocation;

  String currentUri() => di
      .sl<AppRouter>()
      .router
      .routerDelegate
      .currentConfiguration
      .uri
      .toString();

  bool isChipSelected(WidgetTester tester, String label, int count) {
    final chip = tester.widget<ChoiceChip>(
      find.ancestor(
        of: find.text(AppStrings.withCount(label, count)),
        matching: find.byType(ChoiceChip),
      ),
    );

    return chip.selected;
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await settleSession(tester);
  }

  Future<void> bootHome(
    WidgetTester tester, {
    AdminSummaryRemoteDataSource? summarySource,
    UserRole role = UserRole.admin,
  }) async {
    await bootApp(
      tester,
      signedInAs: role,
      adminSummarySource: summarySource,
      memberSource: MemberRosterDataSource(roster),
    );
  }

  testWidgets('an admin lands on the home with the club summary', (
    tester,
  ) async {
    await bootHome(tester);

    expect(currentLocation(), AppRoutes.adminHome);
    expect(find.text('230'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
  });

  testWidgets('the active members card opens Pagos on every member', (
    tester,
  ) async {
    await bootHome(tester);

    await tester.tap(find.byType(SummaryCountCard).first);
    await settleSession(tester);

    expect(
      currentUri(),
      AppRoutes.adminPaymentsWithFilter(MemberCollectionFilter.all.queryValue),
    );
    expect(
        isChipSelected(tester, AppStrings.adminPaymentsFilterAll, 3), isTrue);
  });

  testWidgets('the overdue members card opens Pagos already filtered by mora', (
    tester,
  ) async {
    await bootHome(tester);

    await tester.tap(find.byType(SummaryCountCard).last);
    await settleSession(tester);

    expect(
      currentUri(),
      AppRoutes.adminPaymentsWithFilter(
        MemberCollectionFilter.overdue.queryValue,
      ),
    );
    expect(
      isChipSelected(tester, AppStrings.adminPaymentsFilterOverdue, 1),
      isTrue,
    );
    expect(find.text('Juan Zárate'), findsOneWidget);
    expect(find.text('Ana Álvarez'), findsNothing);
  });

  testWidgets('the member quick access card opens Pagos on every member', (
    tester,
  ) async {
    await bootHome(tester);

    await tester.tap(find.byType(QuickAccessCard).first);
    await settleSession(tester);

    expect(
      currentUri(),
      AppRoutes.adminPaymentsWithFilter(MemberCollectionFilter.all.queryValue),
    );
    expect(
        isChipSelected(tester, AppStrings.adminPaymentsFilterAll, 3), isTrue);
  });

  testWidgets('a card tap moves the bottom navigation onto Pagos', (
    tester,
  ) async {
    await bootHome(tester);

    await tester.tap(find.byType(SummaryCountCard).last);
    await settleSession(tester);

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );

    expect(navigationBar.selectedIndex, 1);
  });

  testWidgets('a second visit from another card re-applies its own filter', (
    tester,
  ) async {
    await bootHome(tester);

    await tester.tap(find.byType(SummaryCountCard).last);
    await settleSession(tester);
    await tapTab(tester, AppStrings.adminTabHome);
    await tester.tap(find.byType(SummaryCountCard).first);
    await settleSession(tester);

    expect(
        isChipSelected(tester, AppStrings.adminPaymentsFilterAll, 3), isTrue);
  });

  testWidgets('the quick access card opens court management', (tester) async {
    await bootHome(tester);

    await tester.tap(find.byType(QuickAccessCard).last);
    await settleSession(tester);

    expect(currentLocation(), AppRoutes.adminCourts);
  });

  testWidgets('a super admin sees the same home surface', (tester) async {
    await bootHome(tester, role: UserRole.superAdmin);

    expect(currentLocation(), AppRoutes.adminHome);
    expect(find.text(AppStrings.roleBadgeSuperAdmin), findsOneWidget);
    expect(find.text('230'), findsOneWidget);
  });

  testWidgets('coming back from a pushed screen shows fresh numbers', (
    tester,
  ) async {
    final dataSource = GrowingClubDataSource();
    await bootHome(tester, summarySource: dataSource);

    await tester.tap(find.byType(QuickAccessCard).last);
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
    await bootHome(tester, summarySource: dataSource);

    await tapTab(tester, AppStrings.adminTabPayments);
    await tapTab(tester, AppStrings.adminTabHome);

    expect(dataSource.calls, 2);
    expect(find.text('231'), findsOneWidget);
  });
}
