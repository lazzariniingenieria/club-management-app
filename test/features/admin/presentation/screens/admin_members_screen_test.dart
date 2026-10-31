import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/theme/app_colors.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/members/data/models/member_model.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/members/presentation/widgets/member_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/app_test_harness.dart';
import '../../../../helpers/member_roster_data_source.dart';

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

  Finder chip(String label, int count) =>
      find.text(AppStrings.withCount(label, count));

  Future<void> openMembersTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(AppStrings.adminTabMembers),
      ),
    );
    await settleSession(tester);
  }

  Future<void> bootMembers(
    WidgetTester tester, {
    List<MemberModel>? members,
  }) async {
    await bootApp(
      tester,
      signedInAs: UserRole.admin,
      memberSource: MemberRosterDataSource(members ?? roster),
    );
    await openMembersTab(tester);
  }

  Future<void> tapChip(WidgetTester tester, String label, int count) async {
    await tester.tap(chip(label, count));
    await settleSession(tester);
  }

  group('roster', () {
    testWidgets('opens on the members still in the club', (tester) async {
      await bootMembers(tester);

      expect(find.byType(MemberListTile), findsNWidgets(2));
      expect(find.text('Juan Zárate'), findsOneWidget);
      expect(find.text('Luis Gómez'), findsNothing);
    });

    testWidgets('only flags what needs attention: en mora, never activo', (
      tester,
    ) async {
      await bootMembers(tester);

      expect(find.text(AppStrings.memberStatusOverdue), findsOneWidget);
      expect(find.text('Activo'), findsNothing);
    });

    testWidgets('opens on the three filter chips with their counters', (
      tester,
    ) async {
      await bootMembers(tester);

      expect(chip(AppStrings.adminMembersFilterAll, 2), findsOneWidget);
      expect(chip(AppStrings.adminMembersFilterOverdue, 1), findsOneWidget);
      expect(chip(AppStrings.adminMembersFilterInactive, 1), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(3));
    });

    testWidgets('a row offers editing and nothing else', (tester) async {
      await bootMembers(tester, members: [roster[1]]);

      expect(
        find.descendant(
          of: find.byType(MemberListTile),
          matching: find.byType(IconButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets('orders the rows by last name ignoring accents', (
      tester,
    ) async {
      await bootMembers(tester);

      final names = tester
          .widgetList<MemberListTile>(find.byType(MemberListTile))
          .map((tile) => tile.member.lastName);

      expect(names, ['Álvarez', 'Zárate']);
    });
  });

  group('filters', () {
    testWidgets('en mora keeps only the members behind on the fee', (
      tester,
    ) async {
      await bootMembers(tester);

      await tapChip(tester, AppStrings.adminMembersFilterOverdue, 1);

      expect(find.byType(MemberListTile), findsOneWidget);
      expect(find.text('Juan Zárate'), findsOneWidget);
    });

    testWidgets('inactivos keeps only the members who were let go', (
      tester,
    ) async {
      await bootMembers(tester);

      await tapChip(tester, AppStrings.adminMembersFilterInactive, 1);

      expect(find.byType(MemberListTile), findsOneWidget);
      expect(find.text('Luis Gómez'), findsOneWidget);
      expect(find.text(AppStrings.memberStatusInactive), findsOneWidget);
    });

    testWidgets('en mora explains itself when every fee is paid', (
      tester,
    ) async {
      await bootMembers(tester, members: [roster[1]]);

      await tapChip(tester, AppStrings.adminMembersFilterOverdue, 0);

      expect(find.text(AppStrings.adminMembersEmptyOverdue), findsOneWidget);
    });
  });

  group('search', () {
    testWidgets('narrows the roster by name typed without accents', (
      tester,
    ) async {
      await bootMembers(tester);

      await tester.enterText(find.byType(TextField), 'alvarez');
      await settleSession(tester);

      expect(find.byType(MemberListTile), findsOneWidget);
      expect(find.text('Ana Álvarez'), findsOneWidget);
    });

    testWidgets('narrows the roster by dni', (tester) async {
      await bootMembers(tester);

      await tester.enterText(find.byType(TextField), '30000002');
      await settleSession(tester);

      expect(find.text('Ana Álvarez'), findsOneWidget);
      expect(find.byType(MemberListTile), findsOneWidget);
    });

    testWidgets('points to Inactivos when only a member let go matches', (
      tester,
    ) async {
      await bootMembers(tester);

      await tester.enterText(find.byType(TextField), 'gomez');
      await settleSession(tester);
      await tester.tap(
        find.text(
          AppStrings.withCount(AppStrings.adminMembersSearchInactive, 1),
        ),
      );
      await settleSession(tester);

      expect(find.text('Luis Gómez'), findsOneWidget);
      expect(find.text(AppStrings.memberStatusInactive), findsOneWidget);
    });

    testWidgets('a search without results offers to clear itself', (
      tester,
    ) async {
      await bootMembers(tester);

      await tester.enterText(find.byType(TextField), 'Rodríguez');
      await settleSession(tester);

      expect(find.text(AppStrings.adminMembersEmptySearch), findsOneWidget);

      await tester.tap(find.text(AppStrings.adminMembersClearSearch));
      await settleSession(tester);

      expect(find.byType(MemberListTile), findsNWidgets(2));
    });

    testWidgets('leaves the chip counters untouched', (tester) async {
      await bootMembers(tester);

      await tester.enterText(find.byType(TextField), 'alvarez');
      await settleSession(tester);

      expect(chip(AppStrings.adminMembersFilterAll, 2), findsOneWidget);
    });
  });

  group('the member form', () {
    testWidgets('creating a member opens the form', (tester) async {
      await bootMembers(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormCreateTitle), findsWidgets);
    });

    testWidgets('editing a member opens the form on that member', (
      tester,
    ) async {
      await bootMembers(tester);

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormEditTitle), findsWidgets);
    });
  });

  group('the filter row', () {
    testWidgets('labels the selected chip in white, not in grey on navy', (
      tester,
    ) async {
      await bootMembers(tester);

      final selected = tester.widget<ChoiceChip>(
        find.ancestor(
          of: chip(AppStrings.adminMembersFilterAll, 2),
          matching: find.byType(ChoiceChip),
        ),
      );
      final unselected = tester.widget<ChoiceChip>(
        find.ancestor(
          of: chip(AppStrings.adminMembersFilterOverdue, 1),
          matching: find.byType(ChoiceChip),
        ),
      );

      expect(selected.labelStyle?.color, AppColors.textOnDark);
      expect(unselected.labelStyle?.color, AppColors.textSecondary);
    });

    testWidgets('fades its edge so hidden chips announce themselves', (
      tester,
    ) async {
      await bootMembers(tester);

      expect(
        find.ancestor(
          of: find.byType(ChoiceChip).first,
          matching: find.byType(ShaderMask),
        ),
        findsOneWidget,
      );
    });

    testWidgets('scrolls sideways to reach a chip that does not fit', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await bootMembers(tester);

      final chipRow = find.ancestor(
        of: find.byType(ChoiceChip).first,
        matching: find.byType(Scrollable),
      );
      final position = tester.widget<Scrollable>(chipRow).controller!.position;
      expect(position.maxScrollExtent, greaterThan(0));

      await tester.drag(chipRow, const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(position.pixels, greaterThan(0));
    });
  });

  group('the create button', () {
    testWidgets('stays on screen on every chip', (tester) async {
      await bootMembers(tester);

      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tapChip(tester, AppStrings.adminMembersFilterOverdue, 1);

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('it clears the last row once the list is scrolled home', (
      tester,
    ) async {
      await bootMembers(
        tester,
        members: [
          for (var id = 1; id <= 20; id++)
            buildMember(
                id: id, lastName: 'Socio ${id.toString().padLeft(2, '0')}'),
        ],
      );

      await tester.scrollUntilVisible(
        find.text('Juan Socio 20'),
        200,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      final createButton = tester.getRect(find.byType(FloatingActionButton));
      final lastRow = tester.getRect(
        find.ancestor(
          of: find.text('Juan Socio 20'),
          matching: find.byType(MemberListTile),
        ),
      );

      expect(createButton.overlaps(lastRow), isFalse);
    });
  });

  group('a refresh that fails', () {
    testWidgets('keeps the roster and reports the failure without wiping it', (
      tester,
    ) async {
      final source = FlakyMemberDataSource(roster);
      await bootApp(
        tester,
        signedInAs: UserRole.admin,
        memberSource: source,
      );
      await openMembersTab(tester);

      source.failsNext = true;
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(find.byType(MemberListTile), findsNWidgets(2));
      expect(chip(AppStrings.adminMembersFilterAll, 2), findsOneWidget);
      expect(find.text(AppStrings.loginNetworkError), findsOneWidget);
    });

    testWidgets('keeps the rows usable while the error is on screen', (
      tester,
    ) async {
      final source = FlakyMemberDataSource(roster);
      await bootApp(
        tester,
        signedInAs: UserRole.admin,
        memberSource: source,
      );
      await openMembersTab(tester);

      source.failsNext = true;
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormEditTitle), findsWidgets);
    });
  });

  group('accessibility', () {
    Future<void> bootAtPhoneSize(WidgetTester tester, double textScale) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await bootMembers(tester);
    }

    testWidgets('renders on a phone at a 130% system text scale', (
      tester,
    ) async {
      await bootAtPhoneSize(tester, 1.3);

      expect(find.byType(MemberListTile), findsWidgets);
      expect(chip(AppStrings.adminMembersFilterAll, 2), findsOneWidget);
    });

    testWidgets('renders on a phone at a 200% system text scale', (
      tester,
    ) async {
      await bootAtPhoneSize(tester, 2);

      expect(find.byType(MemberListTile), findsWidgets);
      expect(chip(AppStrings.adminMembersFilterAll, 2), findsOneWidget);
    });
  });

  group('remote states', () {
    testWidgets('an empty club explains itself instead of a blank list', (
      tester,
    ) async {
      await bootMembers(tester, members: const []);

      expect(find.text(AppStrings.adminMembersEmptyRoster), findsOneWidget);
    });

    testWidgets('a network failure can be retried without leaving', (
      tester,
    ) async {
      await bootApp(
        tester,
        signedInAs: UserRole.admin,
        memberSource: FailingMemberDataSource(NetworkException('offline')),
      );
      await openMembersTab(tester);

      expect(find.text(AppStrings.adminMembersErrorTitle), findsOneWidget);
      expect(find.text(AppStrings.loginNetworkError), findsOneWidget);
      expect(find.text(AppStrings.retryAction), findsOneWidget);
    });
  });
}
