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

  Future<void> openPaymentsTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(AppStrings.adminTabPayments),
      ),
    );
    await settleSession(tester);
  }

  Future<void> bootPayments(
    WidgetTester tester, {
    List<MemberModel>? members,
  }) async {
    await bootApp(
      tester,
      signedInAs: UserRole.admin,
      memberSource: MemberRosterDataSource(members ?? roster),
    );
    await openPaymentsTab(tester);
  }

  Future<void> tapChip(WidgetTester tester, String label, int count) async {
    await tester.tap(chip(label, count));
    await settleSession(tester);
  }

  group('roster', () {
    testWidgets('lists every member with its status badge', (tester) async {
      await bootPayments(tester);

      expect(find.byType(MemberListTile), findsNWidgets(3));
      expect(find.text('Juan Zárate'), findsOneWidget);
      expect(find.text(AppStrings.memberStatusActive), findsNWidgets(2));
      expect(find.text(AppStrings.memberStatusInactive), findsOneWidget);
    });

    testWidgets('opens on the two filter chips with their counters', (
      tester,
    ) async {
      await bootPayments(tester);

      expect(chip(AppStrings.adminPaymentsFilterAll, 3), findsOneWidget);
      expect(chip(AppStrings.adminPaymentsFilterOverdue, 1), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(2));
    });

    testWidgets('a row offers editing and nothing else', (tester) async {
      await bootPayments(tester, members: [roster[1]]);

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
      await bootPayments(tester);

      final names = tester
          .widgetList<MemberListTile>(find.byType(MemberListTile))
          .map((tile) => tile.member.lastName);

      expect(names, ['Álvarez', 'Gómez', 'Zárate']);
    });
  });

  group('filters', () {
    testWidgets('en mora keeps only the members behind on the fee', (
      tester,
    ) async {
      await bootPayments(tester);

      await tapChip(tester, AppStrings.adminPaymentsFilterOverdue, 1);

      expect(find.byType(MemberListTile), findsOneWidget);
      expect(find.text('Juan Zárate'), findsOneWidget);
    });

    testWidgets('en mora explains itself when every fee is paid', (
      tester,
    ) async {
      await bootPayments(tester, members: [roster[1]]);

      await tapChip(tester, AppStrings.adminPaymentsFilterOverdue, 0);

      expect(find.text(AppStrings.adminPaymentsEmptyOverdue), findsOneWidget);
    });
  });

  group('search', () {
    testWidgets('narrows the roster by name typed without accents', (
      tester,
    ) async {
      await bootPayments(tester);

      await tester.enterText(find.byType(TextField), 'alvarez');
      await settleSession(tester);

      expect(find.byType(MemberListTile), findsOneWidget);
      expect(find.text('Ana Álvarez'), findsOneWidget);
    });

    testWidgets('narrows the roster by dni', (tester) async {
      await bootPayments(tester);

      await tester.enterText(find.byType(TextField), '30000003');
      await settleSession(tester);

      expect(find.text('Luis Gómez'), findsOneWidget);
      expect(find.byType(MemberListTile), findsOneWidget);
    });

    testWidgets('a search without results offers to clear itself', (
      tester,
    ) async {
      await bootPayments(tester);

      await tester.enterText(find.byType(TextField), 'Rodríguez');
      await settleSession(tester);

      expect(find.text(AppStrings.adminPaymentsEmptySearch), findsOneWidget);

      await tester.tap(find.text(AppStrings.adminPaymentsClearSearch));
      await settleSession(tester);

      expect(find.byType(MemberListTile), findsNWidgets(3));
    });

    testWidgets('leaves the chip counters untouched', (tester) async {
      await bootPayments(tester);

      await tester.enterText(find.byType(TextField), 'alvarez');
      await settleSession(tester);

      expect(chip(AppStrings.adminPaymentsFilterAll, 3), findsOneWidget);
    });
  });

  group('the member form', () {
    testWidgets('creating a member opens the form', (tester) async {
      await bootPayments(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormCreateTitle), findsWidgets);
    });

    testWidgets('editing a member opens the form on that member', (
      tester,
    ) async {
      await bootPayments(tester);

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormEditTitle), findsWidgets);
    });
  });

  group('the filter row', () {
    testWidgets('labels the selected chip in white, not in grey on navy', (
      tester,
    ) async {
      await bootPayments(tester);

      final selected = tester.widget<ChoiceChip>(
        find.ancestor(
          of: chip(AppStrings.adminPaymentsFilterAll, 3),
          matching: find.byType(ChoiceChip),
        ),
      );
      final unselected = tester.widget<ChoiceChip>(
        find.ancestor(
          of: chip(AppStrings.adminPaymentsFilterOverdue, 1),
          matching: find.byType(ChoiceChip),
        ),
      );

      expect(selected.labelStyle?.color, AppColors.textOnDark);
      expect(unselected.labelStyle?.color, AppColors.textSecondary);
    });

    testWidgets('fades its edge so hidden chips announce themselves', (
      tester,
    ) async {
      await bootPayments(tester);

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

      await bootPayments(tester);

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
      await bootPayments(tester);

      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tapChip(tester, AppStrings.adminPaymentsFilterOverdue, 1);

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('it clears the last row once the list is scrolled home', (
      tester,
    ) async {
      await bootPayments(
        tester,
        members: [for (var id = 1; id <= 20; id++) buildMember(id: id)],
      );

      await tester.drag(find.byType(ListView), const Offset(0, -4000));
      await tester.pumpAndSettle();

      final createButton = tester.getRect(find.byType(FloatingActionButton));
      final lastRow = tester.getRect(find.byType(MemberListTile).last);

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
      await openPaymentsTab(tester);

      source.failsNext = true;
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(find.byType(MemberListTile), findsNWidgets(3));
      expect(chip(AppStrings.adminPaymentsFilterAll, 3), findsOneWidget);
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
      await openPaymentsTab(tester);

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

      await bootPayments(tester);
    }

    testWidgets('renders on a phone at a 130% system text scale', (
      tester,
    ) async {
      await bootAtPhoneSize(tester, 1.3);

      expect(find.byType(MemberListTile), findsWidgets);
      expect(chip(AppStrings.adminPaymentsFilterAll, 3), findsOneWidget);
    });

    testWidgets('renders on a phone at a 200% system text scale', (
      tester,
    ) async {
      await bootAtPhoneSize(tester, 2);

      expect(find.byType(MemberListTile), findsWidgets);
      expect(chip(AppStrings.adminPaymentsFilterAll, 3), findsOneWidget);
    });
  });

  group('remote states', () {
    testWidgets('an empty club explains itself instead of a blank list', (
      tester,
    ) async {
      await bootPayments(tester, members: const []);

      expect(find.text(AppStrings.adminPaymentsEmptyRoster), findsOneWidget);
    });

    testWidgets('a network failure can be retried without leaving', (
      tester,
    ) async {
      await bootApp(
        tester,
        signedInAs: UserRole.admin,
        memberSource: FailingMemberDataSource(NetworkException('offline')),
      );
      await openPaymentsTab(tester);

      expect(find.text(AppStrings.adminPaymentsErrorTitle), findsOneWidget);
      expect(find.text(AppStrings.loginNetworkError), findsOneWidget);
      expect(find.text(AppStrings.retryAction), findsOneWidget);
    });
  });
}
