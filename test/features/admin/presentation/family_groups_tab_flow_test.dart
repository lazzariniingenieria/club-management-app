import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/admin/presentation/widgets/family_groups_tab.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/family_groups/presentation/widgets/family_group_list_tile.dart';
import 'package:club_management_app/features/members/data/datasources/member_fake_data_source.dart';
import 'package:club_management_app/features/members/presentation/widgets/member_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

void main() {
  String currentUri() => di
      .sl<AppRouter>()
      .router
      .routerDelegate
      .currentConfiguration
      .uri
      .toString();

  String currentLocation() => di
      .sl<AppRouter>()
      .router
      .routerDelegate
      .currentConfiguration
      .last
      .matchedLocation;

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> openGroupsTab(WidgetTester tester) async {
    await bootApp(
      tester,
      signedInAs: UserRole.admin,
      memberSource: MemberFakeDataSource(latency: Duration.zero),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(AppStrings.adminTabMembers),
      ),
    );
    await settleSession(tester);
    await tapText(tester, AppStrings.adminMembersTabFamilyGroups);
  }

  testWidgets('the members tab opens on Socios', (tester) async {
    await bootApp(tester, signedInAs: UserRole.admin);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(AppStrings.adminTabMembers),
      ),
    );
    await settleSession(tester);

    expect(find.byType(MemberListTile), findsWidgets);
    expect(find.byType(FamilyGroupsTab), findsNothing);
  });

  testWidgets('Grupos familiares lists every group with its members', (
    tester,
  ) async {
    await openGroupsTab(tester);

    expect(currentUri(), AppRoutes.adminFamilyGroups);
    expect(find.byType(FamilyGroupListTile), findsNWidgets(2));
    expect(find.text('Familia Álvarez'), findsOneWidget);
    expect(find.text(AppStrings.familyGroupFallbackName), findsOneWidget);
    expect(find.byTooltip(AppStrings.familyGroupsBuildAction), findsOneWidget);
  });

  testWidgets('a group behind on the fee is flagged en mora', (tester) async {
    await openGroupsTab(tester);

    expect(
      find.descendant(
        of: find.byType(FamilyGroupListTile).first,
        matching: find.text(AppStrings.memberStatusOverdue),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a group opens it', (tester) async {
    await openGroupsTab(tester);

    await tapText(tester, 'Familia Álvarez');

    expect(currentLocation(), AppRoutes.adminFamilyGroup(1));
  });

  testWidgets('the search narrows the groups by name', (tester) async {
    await openGroupsTab(tester);

    await tester.enterText(find.byType(TextField), 'familia');
    await settleSession(tester);

    expect(find.byType(FamilyGroupListTile), findsOneWidget);
  });

  testWidgets('going back to Socios keeps the chip it had', (tester) async {
    await openGroupsTab(tester);
    di.sl<AppRouter>().router.go(AppRoutes.adminFamilyGroups);
    await settleSession(tester);

    await tapText(tester, AppStrings.adminMembersTabMembers);

    expect(find.byType(MemberListTile), findsWidgets);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('a home card always lands on Socios, not on the groups', (
    tester,
  ) async {
    await openGroupsTab(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(AppStrings.adminTabHome),
      ),
    );
    await settleSession(tester);

    await tester.tap(find.text(AppStrings.adminHomeOverdueMembers.toUpperCase()));
    await settleSession(tester);

    expect(find.byType(FamilyGroupsTab), findsNothing);
    expect(find.byType(MemberListTile), findsWidgets);
  });

  group('armar grupo', () {
    testWidgets('asks first for a member who has no group yet', (
      tester,
    ) async {
      await openGroupsTab(tester);

      await tester.tap(find.byTooltip(AppStrings.familyGroupsBuildAction));
      await tester.pumpAndSettle();

      expect(currentLocation(), AppRoutes.adminFamilyGroupStart);
      expect(find.text(AppStrings.familyGroupStartQuestion), findsOneWidget);
      final roster = (await tester.runAsync(
        MemberFakeDataSource(latency: Duration.zero).fetchMembers,
      ))!;
      final grouped = roster.where((member) => member.familyGroupId != null);
      for (final member in grouped) {
        expect(find.text(member.fullName), findsNothing);
      }
    });

    testWidgets('builds the group and comes back to the list with a notice', (
      tester,
    ) async {
      await openGroupsTab(tester);
      await tester.tap(find.byTooltip(AppStrings.familyGroupsBuildAction));
      await tester.pumpAndSettle();
      final first = find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(InkWell),
      );

      await tester.tap(first.first);
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.familyGroupBuildConfirm));
      await tester.pumpAndSettle();

      expect(currentUri(), AppRoutes.adminFamilyGroups);
      expect(find.byType(FamilyGroupListTile), findsNWidgets(3));
      expect(find.textContaining('Grupo familiar armado'), findsOneWidget);
    });
  });
}
