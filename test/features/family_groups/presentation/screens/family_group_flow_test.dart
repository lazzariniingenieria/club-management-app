import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/members/data/datasources/member_fake_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/app_test_harness.dart';

void main() {
  late MemberFakeDataSource members;

  Future<void> openRoute(WidgetTester tester, String location) async {
    di.sl<AppRouter>().router.push(location);
    await tester.pumpAndSettle();
  }

  Future<void> boot(WidgetTester tester) async {
    members = MemberFakeDataSource(latency: Duration.zero);
    await bootApp(tester, signedInAs: UserRole.admin, memberSource: members);
  }

  testWidgets('builds a group from the ledger of a member without one', (
    tester,
  ) async {
    await boot(tester);
    await openRoute(tester, AppRoutes.adminMemberLedger(4));

    await tester.ensureVisible(find.text(AppStrings.familyGroupBuildAction));
    await tester.tap(find.text(AppStrings.familyGroupBuildAction));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Martín Álv');
    await tester.pump();
    await tester.tap(find.text('Martín Álvarez'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.familyGroupConfirmBuildTitle), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Familia Álvarez'), findsOneWidget);

    await tester.tap(find.text(AppStrings.familyGroupBuildConfirm));
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.familyGroupBuilt('Martín Álvarez')),
      findsOneWidget,
    );
    final roster = (await tester.runAsync(members.fetchMembers))!;
    final lucia = roster.firstWhere((member) => member.id == 4);
    final martin = roster.firstWhere((member) => member.id == 5);
    expect(lucia.familyGroupId, isNotNull);
    expect(martin.familyGroupId, lucia.familyGroupId);
  });

  testWidgets('a member joins the group the relative is already in', (
    tester,
  ) async {
    await boot(tester);
    await openRoute(tester, AppRoutes.adminFamilyGroupCreation(4));

    await tester.enterText(find.byType(TextField), 'Juan Álv');
    await tester.pump();
    await tester.tap(find.text('Juan Álvarez'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        AppStrings.familyGroupConfirmJoinTitle(
          'Lucía Álvarez',
          'Familia Álvarez',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text(AppStrings.familyGroupJoinConfirm));
    await tester.pumpAndSettle();

    final roster = (await tester.runAsync(members.fetchMembers))!;
    expect(roster.firstWhere((member) => member.id == 4).familyGroupId, 1);
  });

  testWidgets('the group screen lists the members and removes one', (
    tester,
  ) async {
    await boot(tester);
    await openRoute(tester, AppRoutes.adminFamilyGroup(1));

    expect(find.text('Familia Álvarez'), findsOneWidget);
    expect(find.text(AppStrings.familyGroupMembersSection(3)), findsOneWidget);

    await tester.tap(
      find.bySemanticsLabel(
        AppStrings.familyGroupRemoveSemantics('Carlos Álvarez'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.familyGroupRemoveConfirm));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.familyGroupMembersSection(2)), findsOneWidget);
    expect(
      find.text(AppStrings.familyGroupMemberRemoved('Carlos Álvarez')),
      findsOneWidget,
    );
  });

  testWidgets('an unknown group explains it was not found', (tester) async {
    await boot(tester);
    await openRoute(tester, AppRoutes.adminFamilyGroup(99));

    expect(find.text(AppStrings.familyGroupMissingTitle), findsOneWidget);
  });
}
