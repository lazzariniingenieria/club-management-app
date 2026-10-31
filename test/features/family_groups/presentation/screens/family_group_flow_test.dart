import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'dart:async';

import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/family_groups/data/datasources/family_group_fake_data_source.dart';
import 'package:club_management_app/features/family_groups/data/models/family_group_model.dart';
import 'package:club_management_app/features/members/data/datasources/member_fake_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/app_test_harness.dart';

class CountingGroupSource extends FamilyGroupFakeDataSource {
  CountingGroupSource({required super.members}) : super(latency: Duration.zero);

  int attempts = 0;
  bool failsOnce = false;
  Completer<void>? holdCreation;
  Completer<void>? holdDeletion;

  @override
  Future<void> deleteGroup(int familyGroupId) async {
    await holdDeletion?.future;

    return super.deleteGroup(familyGroupId);
  }

  @override
  Future<FamilyGroupModel> createGroup({
    String? name,
    List<int> memberIds = const [],
  }) async {
    attempts++;
    await holdCreation?.future;
    if (failsOnce) {
      failsOnce = false;
      throw ServerException('boom');
    }

    return super.createGroup(name: name, memberIds: memberIds);
  }
}

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

  group('building a group that does not go through', () {
    late CountingGroupSource groups;

    Future<void> bootWithCountingGroups(WidgetTester tester) async {
      members = MemberFakeDataSource(latency: Duration.zero);
      groups = CountingGroupSource(members: members);
      await bootApp(
        tester,
        signedInAs: UserRole.admin,
        memberSource: members,
        familyGroupSource: groups,
      );
      await openRoute(tester, AppRoutes.adminFamilyGroupCreation(4));
    }

    Future<void> pickMartin(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField), 'Martín Álv');
      await tester.pump();
      await tester.tap(find.text('Martín Álvarez'));
      await tester.pumpAndSettle();
    }

    testWidgets('offers to retry and creates one group with both members', (
      tester,
    ) async {
      await bootWithCountingGroups(tester);
      groups.failsOnce = true;
      await pickMartin(tester);

      await tester.tap(find.text(AppStrings.familyGroupBuildConfirm));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(AppStrings.familyGroupServerTitle),
        findsOneWidget,
      );
      var roster = (await tester.runAsync(members.fetchMembers))!;
      expect(roster.firstWhere((member) => member.id == 4).familyGroupId, isNull);

      await tester.tap(find.text(AppStrings.retryAction));
      await tester.pumpAndSettle();

      expect(groups.attempts, 2);
      roster = (await tester.runAsync(members.fetchMembers))!;
      final lucia = roster.firstWhere((member) => member.id == 4);
      final martin = roster.firstWhere((member) => member.id == 5);
      expect(lucia.familyGroupId, isNotNull);
      expect(martin.familyGroupId, lucia.familyGroupId);
      expect(await tester.runAsync(groups.fetchGroups), hasLength(3));
    });

    testWidgets(
        'a member grouped by somebody else meanwhile refreshes the list '
        'instead of retrying', (tester) async {
      await bootWithCountingGroups(tester);
      await pickMartin(tester);
      await tester.runAsync(() => members.assignFamilyGroup(5, 1));

      await tester.tap(find.text(AppStrings.familyGroupBuildConfirm));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(AppStrings.familyGroupStaleTitle),
        findsOneWidget,
      );
      expect(find.text(AppStrings.familyGroupBuildConfirm), findsNothing);
      expect(find.text(AppStrings.retryAction), findsNothing);

      await tester.tap(find.text(AppStrings.backAction));
      await tester.pumpAndSettle();
      await pickMartin(tester);

      expect(
        find.text(
          AppStrings.familyGroupConfirmJoinTitle(
            'Lucía Álvarez',
            'Familia Álvarez',
          ),
        ),
        findsOneWidget,
      );
      final roster = (await tester.runAsync(members.fetchMembers))!;
      expect(roster.firstWhere((member) => member.id == 4).familyGroupId, isNull);
    });

    testWidgets('the sheet cannot be closed while it saves', (tester) async {
      await bootWithCountingGroups(tester);
      groups.holdCreation = Completer<void>();
      await pickMartin(tester);

      await tester.tap(find.text(AppStrings.familyGroupBuildConfirm));
      await tester.pump();
      final cancel = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, AppStrings.cancelAction),
      );
      expect(cancel.onPressed, isNull);

      await tester.binding.handlePopRoute();
      await tester.tapAt(const Offset(20, 20));
      await tester.pump();
      expect(find.text(AppStrings.familyGroupConfirmBuildTitle), findsOneWidget);

      groups.holdCreation!.complete();
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.familyGroupConfirmBuildTitle), findsNothing);
    });
  });

  group('deleting a group', () {
    testWidgets('asks to confirm and leaves its members without a group', (
      tester,
    ) async {
      await boot(tester);
      await openRoute(tester, AppRoutes.adminFamilyGroup(1));
      final before = (await tester.runAsync(members.fetchMembers))!;
      final inGroup = before
          .where((member) => member.familyGroupId == 1)
          .map((member) => member.id)
          .toList();
      expect(inGroup, isNotEmpty);

      await tester.scrollUntilVisible(
        find.text(AppStrings.familyGroupDeleteAction),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(AppStrings.familyGroupDeleteAction));
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.familyGroupDeleteTitle('Familia Álvarez')),
        findsOneWidget,
      );
      await tester.tap(find.text(AppStrings.familyGroupDeleteConfirm));
      await tester.pumpAndSettle();

      final after = (await tester.runAsync(members.fetchMembers))!;
      expect(
        after.where((member) => inGroup.contains(member.id)).map(
              (member) => member.familyGroupId,
            ),
        everyElement(isNull),
      );
      expect(find.text(AppStrings.familyGroupDeleted), findsOneWidget);
      expect(find.text(AppStrings.familyGroupScreenTitle), findsNothing);
    });

    testWidgets(
        'a second tap while the deletion is in flight opens no second dialog '
        'and still leaves the screen', (tester) async {
      members = MemberFakeDataSource(latency: Duration.zero);
      final groups = CountingGroupSource(members: members)
        ..holdDeletion = Completer<void>();
      await bootApp(
        tester,
        signedInAs: UserRole.admin,
        memberSource: members,
        familyGroupSource: groups,
      );
      await openRoute(tester, AppRoutes.adminFamilyGroup(1));
      await tester.scrollUntilVisible(
        find.text(AppStrings.familyGroupDeleteAction),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text(AppStrings.familyGroupDeleteAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.familyGroupDeleteConfirm));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(
        find.text(AppStrings.familyGroupDeleteAction),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(AppStrings.familyGroupDeleteConfirm), findsNothing);

      groups.holdDeletion!.complete();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.familyGroupDeleteConfirm), findsNothing);
      expect(find.text(AppStrings.familyGroupScreenTitle), findsNothing);
    });

    testWidgets('cancelling leaves the group as it was', (tester) async {
      await boot(tester);
      await openRoute(tester, AppRoutes.adminFamilyGroup(1));

      await tester.scrollUntilVisible(
        find.text(AppStrings.familyGroupDeleteAction),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(AppStrings.familyGroupDeleteAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.cancelAction));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.familyGroupScreenTitle), findsOneWidget);
      expect(find.text(AppStrings.familyGroupDeleted), findsNothing);
      final roster = (await tester.runAsync(members.fetchMembers))!;
      expect(roster.where((member) => member.familyGroupId == 1), isNotEmpty);
    });
  });

  testWidgets('building a group for an unknown member says nothing of payments',
      (tester) async {
    await boot(tester);
    await openRoute(tester, AppRoutes.adminFamilyGroupCreation(999));

    expect(find.text(AppStrings.ledgerMissingTitle), findsOneWidget);
    expect(find.text(AppStrings.familyGroupMemberMissingMessage), findsOneWidget);
    expect(find.textContaining('pago'), findsNothing);
  });

  testWidgets('an unknown group explains it was not found', (tester) async {
    await boot(tester);
    await openRoute(tester, AppRoutes.adminFamilyGroup(99));

    expect(find.text(AppStrings.familyGroupMissingTitle), findsOneWidget);
  });
}
