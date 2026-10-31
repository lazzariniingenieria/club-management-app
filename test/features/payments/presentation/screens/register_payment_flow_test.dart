import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/members/data/models/member_model.dart';
import 'package:club_management_app/features/members/data/datasources/member_remote_data_source.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_draft.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/data/models/member_ledger_model.dart';
import 'package:club_management_app/features/payments/presentation/screens/payment_member_picker_screen.dart';
import 'package:club_management_app/features/payments/presentation/widgets/payment_history_tile.dart';
import 'package:club_management_app/features/payments/data/datasources/payment_fake_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/app_test_harness.dart';
import '../../../../helpers/member_roster_data_source.dart';
import '../../../../helpers/payment_builders.dart';

class DroppingPaymentSource extends PaymentFakeDataSource {
  int dropsLeft;
  int recorded = 0;

  DroppingPaymentSource({
    required super.members,
    this.dropsLeft = 1,
  }) : super(
          latency: Duration.zero,
          clock: () => DateTime(2026, 10, 14),
        );

  @override
  Future<void> recordPayment(PaymentDraft draft) async {
    if (dropsLeft > 0) {
      dropsLeft--;
      throw NetworkException('offline');
    }
    recorded++;
    await super.recordPayment(draft);
  }
}

class RecordingPaymentSource extends PaymentFakeDataSource {
  final List<PaymentDraft> drafts = [];
  final List<List<PaymentDraft>> batches = [];

  RecordingPaymentSource({required super.members})
      : super(latency: Duration.zero, clock: () => DateTime(2026, 10, 14));

  @override
  Future<void> recordPayment(PaymentDraft draft) async {
    await super.recordPayment(draft);
    drafts.add(draft);
  }

  @override
  Future<void> recordPayments(List<PaymentDraft> drafts) async {
    await super.recordPayments(drafts);
    batches.add(drafts);
    this.drafts.addAll(drafts);
  }
}

class DroppedBatchPaymentSource extends PaymentFakeDataSource {
  final Exception error;
  final bool landsAnyway;
  int sent = 0;
  int failuresLeft = 1;

  DroppedBatchPaymentSource({
    required super.members,
    required this.error,
    this.landsAnyway = false,
  }) : super(latency: Duration.zero, clock: () => DateTime(2026, 10, 14));

  @override
  Future<void> recordPayments(List<PaymentDraft> drafts) async {
    sent++;
    if (failuresLeft > 0) {
      failuresLeft--;
      if (landsAnyway) await super.recordPayments(drafts);
      throw error;
    }
    await super.recordPayments(drafts);
  }
}

class CollectedMonthPaymentSource extends PaymentFakeDataSource {
  final int collectedMemberId;
  bool collectsNext = true;

  CollectedMonthPaymentSource({
    required super.members,
    required this.collectedMemberId,
  }) : super(latency: Duration.zero, clock: () => DateTime(2026, 10, 14));

  @override
  Future<void> recordPayments(List<PaymentDraft> drafts) async {
    if (!collectsNext) return super.recordPayments(drafts);

    collectsNext = false;
    await super.recordPayment(
      drafts.firstWhere((draft) => draft.memberId == collectedMemberId),
    );
    throw ConflictException('a period is already paid');
  }
}

class LeavingRelativePaymentSource extends PaymentFakeDataSource {
  final List<MemberModel> roster;
  final int leavingMemberId;

  LeavingRelativePaymentSource({
    required super.members,
    required this.roster,
    required this.leavingMemberId,
  }) : super(latency: Duration.zero, clock: () => DateTime(2026, 10, 14));

  @override
  Future<void> recordPayments(List<PaymentDraft> drafts) async {
    if (!drafts.any((draft) => draft.memberId == leavingMemberId)) {
      return super.recordPayments(drafts);
    }

    final index = roster.indexWhere((member) => member.id == leavingMemberId);
    final leaving = roster[index];
    roster[index] = buildMember(
      id: leaving.id,
      firstName: leaving.firstName,
      lastName: leaving.lastName,
      daysOverdue: leaving.daysOverdue,
    );
    throw ValidationException('not in the group');
  }
}

class LongHistoryPaymentSource extends PaymentFakeDataSource {
  static const int paymentCount = 60;

  LongHistoryPaymentSource({required super.members})
      : super(latency: Duration.zero, clock: () => DateTime(2026, 10, 14));

  @override
  Future<MemberLedgerModel> fetchLedger(int memberId) async {
    final current = await super.fetchLedger(memberId);
    var month = const BillingMonth(2026, 9);

    return MemberLedgerModel(
      member: current.member,
      familyMembers: current.familyMembers,
      memberNames: current.memberNames,
      monthlyFeeCents: current.monthlyFeeCents,
      payments: [
        for (var id = 1; id <= paymentCount; id++, month = month.previous)
          buildPayment(id: id, memberId: memberId, month: month),
      ],
    );
  }
}

class CountingLedgerSource extends PaymentFakeDataSource {
  int ledgerReads = 0;

  CountingLedgerSource({required super.members})
      : super(latency: Duration.zero, clock: () => DateTime(2026, 10, 14));

  @override
  Future<MemberLedgerModel> fetchLedger(int memberId) {
    ledgerReads++;

    return super.fetchLedger(memberId);
  }
}

class DeactivatableRosterSource extends MemberRosterDataSource {
  DeactivatableRosterSource(super.roster);

  @override
  Future<void> setMemberActive(int memberId, {required bool isActive}) async {
    final index = roster.indexWhere((member) => member.id == memberId);
    final current = roster[index];

    roster[index] = buildMember(
      id: current.id,
      firstName: current.firstName,
      lastName: current.lastName,
      status: isActive ? MemberStatus.active : MemberStatus.inactive,
    );
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

  Future<void> bootClub(
    WidgetTester tester, {
    PaymentFakeDataSource Function(MemberRemoteDataSource members)? payments,
    MemberRosterDataSource? memberSource,
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final members = memberSource ?? MemberRosterDataSource(roster);
    await bootApp(
      tester,
      signedInAs: UserRole.admin,
      memberSource: members,
      paymentSource: payments?.call(members) ??
          PaymentFakeDataSource(
            members: members,
            latency: Duration.zero,
            clock: () => DateTime(2026, 10, 14),
          ),
    );
  }

  Future<void> openMembersTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(AppStrings.adminTabMembers),
      ),
    );
    await settleSession(tester);
  }

  Future<void> openLedgerOf(WidgetTester tester, String name) async {
    await openMembersTab(tester);
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  Future<void> reviewAndConfirm(WidgetTester tester, String total) async {
    await tester.tap(
      find.text(AppStrings.registerPaymentReviewWithTotal(total)),
    );
    await tester.pumpAndSettle();
    final confirm = find.text(AppStrings.confirmPaymentAction(total));
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
  }

  group('from the Pagos tab', () {
    testWidgets('tapping a member opens their ledger', (tester) async {
      await bootClub(tester);
      await openMembersTab(tester);

      await tester.tap(find.text('Juan Zárate'));
      await tester.pumpAndSettle();

      expect(currentLocation(), AppRoutes.adminMemberLedger(1));
      expect(find.text(AppStrings.daysOverdueBadge(42)), findsOneWidget);
      expect(
        find.text(AppStrings.ledgerLastPaid('agosto 2026')),
        findsOneWidget,
      );
    });

    testWidgets('a payment registered from the ledger shows up in it', (
      tester,
    ) async {
      await bootClub(tester);
      await openMembersTab(tester);
      await tester.tap(find.text('Juan Zárate'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.ledgerRegisterAction));
      await tester.pumpAndSettle();
      expect(
        find.text(
          AppStrings.registerPaymentSuggestionAfterLastPaid('septiembre'),
        ),
        findsOneWidget,
      );
      await reviewAndConfirm(tester, r'$15.000');

      expect(currentLocation(), AppRoutes.adminMemberLedger(1));
      expect(
        find.text(
          AppStrings.paymentRegistered('septiembre de 2026', r'$15.000'),
        ),
        findsOneWidget,
      );
      expect(find.text(AppStrings.ledgerNewTag), findsOneWidget);
    });
  });

  group('from the home card', () {
    Future<void> openPicker(WidgetTester tester) async {
      await bootClub(tester);
      await tester.tap(find.text(AppStrings.adminHomeRegisterPaymentAccess));
      await settleSession(tester);
    }

    testWidgets('lists the members who owe first and leaves out inactives', (
      tester,
    ) async {
      await openPicker(tester);

      expect(
        find.text(AppStrings.paymentPickerOverdueSection(1)),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.paymentPickerUpToDateSection(1)),
        findsOneWidget,
      );
      expect(find.text('Luis Gómez'), findsNothing);

      final overdueTop = tester.getTopLeft(find.text('Juan Zárate')).dy;
      final upToDateTop = tester.getTopLeft(find.text('Ana Álvarez')).dy;
      expect(overdueTop, lessThan(upToDateTop));
    });

    testWidgets('finds a member by dni', (tester) async {
      await openPicker(tester);

      await tester.enterText(find.byType(TextField), roster[1].dni);
      await settleSession(tester);

      expect(find.text('Ana Álvarez'), findsOneWidget);
      expect(find.text('Juan Zárate'), findsNothing);
    });

    testWidgets('ends on the ledger of the member that just paid', (
      tester,
    ) async {
      await openPicker(tester);

      await tester.tap(find.text('Ana Álvarez'));
      await tester.pumpAndSettle();
      await reviewAndConfirm(tester, r'$15.000');

      expect(currentLocation(), AppRoutes.adminMemberLedger(2));
      expect(
        find.text(
          AppStrings.paymentRegistered('noviembre de 2026', r'$15.000'),
        ),
        findsOneWidget,
      );

      di.sl<AppRouter>().router.pop();
      await settleSession(tester);
      expect(currentLocation(), AppRoutes.adminHome);
    });
  });

  group('recovering from a failed attempt', () {
    testWidgets('retrying after losing the connection asks to confirm again', (
      tester,
    ) async {
      late DroppingPaymentSource source;
      await bootClub(
        tester,
        payments: (members) => source = DroppingPaymentSource(members: members),
      );
      await openLedgerOf(tester, 'Juan Zárate');
      await tester.tap(find.text(AppStrings.ledgerRegisterAction));
      await tester.pumpAndSettle();
      await reviewAndConfirm(tester, r'$15.000');

      expect(
        find.textContaining(
          AppStrings.registerPaymentOfflineTitle,
          findRichText: true,
        ),
        findsOneWidget,
      );

      await tester.tap(find.text(AppStrings.retryAction));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.confirmPaymentTitle), findsOneWidget);
      expect(source.recorded, 0);

      final confirm = find.text(AppStrings.confirmPaymentAction(r'$15.000'));
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(source.recorded, 1);
      expect(currentLocation(), AppRoutes.adminMemberLedger(1));
    });
  });

  group('a member deactivated from their ledger', () {
    testWidgets('can no longer be charged when the admin comes back', (
      tester,
    ) async {
      await bootClub(
        tester,
        memberSource: DeactivatableRosterSource([...roster]),
      );
      await openLedgerOf(tester, 'Ana Álvarez');

      await tester.tap(find.byTooltip(AppStrings.memberEditAction));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(AppStrings.memberDeactivateAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.memberDeactivateAction));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(AppStrings.memberDeactivateAction),
        ),
      );
      await tester.pumpAndSettle();

      expect(currentLocation(), AppRoutes.adminMemberLedger(2));
      expect(find.text(AppStrings.ledgerInactiveHint), findsOneWidget);
      expect(find.text(AppStrings.ledgerRegisterAction), findsNothing);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('cannot be charged by opening the payment screen directly', (
      tester,
    ) async {
      await bootClub(tester);
      await openMembersTab(tester);

      di.sl<AppRouter>().router.push(AppRoutes.adminPaymentRegistration(3));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.registerPaymentInactiveTitle),
        findsOneWidget,
      );
      expect(find.text(AppStrings.confirmPaymentTitle), findsNothing);
    });
  });

  group('voiding a payment from the ledger', () {
    Future<void> openVoidSheetOfLastPayment(WidgetTester tester) async {
      await bootClub(tester);
      await openLedgerOf(tester, 'Juan Zárate');

      final lastPayment = find.byType(PaymentHistoryTile).first;
      await tester.ensureVisible(lastPayment);
      await tester.pumpAndSettle();
      await tester.tap(lastPayment);
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.paymentDetailTitle('agosto 2026')),
        findsOneWidget,
      );

      await tester.tap(find.text(AppStrings.paymentDetailVoidAction));
      await tester.pumpAndSettle();
    }

    Future<void> scrollLedgerToTop(WidgetTester tester) async {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
      await tester.pumpAndSettle();
    }

    testWidgets('asks to confirm and explains it cannot be undone', (
      tester,
    ) async {
      await openVoidSheetOfLastPayment(tester);

      expect(
        find.text(AppStrings.voidPaymentTitle('agosto 2026')),
        findsOneWidget,
      );
      expect(
        find.textContaining(AppStrings.voidPaymentEffect, findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('keeps the payment struck through with its reason', (
      tester,
    ) async {
      await openVoidSheetOfLastPayment(tester);

      await tester.enterText(find.byType(TextField), 'Socio equivocado');
      await tester.tap(find.text(AppStrings.voidPaymentConfirmAction));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.voidPaymentDone('agosto 2026')),
        findsOneWidget,
      );
      expect(find.text(AppStrings.paymentVoidedTag), findsOneWidget);
      expect(
        find.text(AppStrings.paymentVoidReason('Socio equivocado')),
        findsOneWidget,
      );
      await scrollLedgerToTop(tester);
      expect(find.text(AppStrings.ledgerLastPaid('julio 2026')), findsWidgets);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('cancelling leaves the payment as it was', (tester) async {
      await openVoidSheetOfLastPayment(tester);

      await tester.tap(find.text(AppStrings.cancelAction));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.paymentVoidedTag), findsNothing);
      await scrollLedgerToTop(tester);
      expect(
        find.text(AppStrings.ledgerLastPaid('agosto 2026')),
        findsWidgets,
      );
    });
  });

  group('a long list', () {
    Finder scrollableAround(Finder child) =>
        find.ancestor(of: child, matching: find.byType(Scrollable)).first;

    testWidgets('of members to pick builds only the tiles on screen', (
      tester,
    ) async {
      final crowd = [
        for (var id = 1; id <= 200; id++)
          buildMember(
            id: id,
            firstName: 'Socio',
            lastName: 'Apellido${id.toString().padLeft(3, '0')}',
          ),
      ];
      await bootClub(tester, memberSource: MemberRosterDataSource(crowd));
      await tester.tap(find.text(AppStrings.adminHomeRegisterPaymentAccess));
      await settleSession(tester);

      final last = find.text('Socio Apellido200');
      expect(last, findsNothing);

      await tester.scrollUntilVisible(
        last,
        2000,
        scrollable: scrollableAround(find.byType(PaymentMemberPickerTile)),
      );
      expect(last, findsOneWidget);
    });

    testWidgets('of payments in the ledger builds only the tiles on screen', (
      tester,
    ) async {
      await bootClub(
        tester,
        payments: (members) => LongHistoryPaymentSource(members: members),
      );
      await openLedgerOf(tester, 'Juan Zárate');

      final oldest = find.byWidgetPredicate(
        (widget) =>
            widget is PaymentHistoryTile &&
            widget.payment.id == LongHistoryPaymentSource.paymentCount,
      );
      expect(oldest, findsNothing);

      await tester.scrollUntilVisible(
        oldest,
        2000,
        scrollable: scrollableAround(find.byType(PaymentHistoryTile)),
      );
      expect(oldest, findsOneWidget);
    });
  });

  testWidgets('pulling the ledger down reloads it', (tester) async {
    late CountingLedgerSource source;
    await bootClub(
      tester,
      payments: (members) => source = CountingLedgerSource(members: members),
    );
    await openLedgerOf(tester, 'Juan Zárate');
    final readsBefore = source.ledgerReads;

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(source.ledgerReads, readsBefore + 1);
  });

  group('the ledger of an inactive member', () {
    testWidgets('explains why it cannot be charged and offers to edit', (
      tester,
    ) async {
      await bootClub(tester);
      await openMembersTab(tester);
      final inactiveChip =
          find.textContaining(AppStrings.adminMembersFilterInactive);
      await tester.ensureVisible(inactiveChip);
      await tester.pumpAndSettle();
      await tester.tap(inactiveChip);
      await settleSession(tester);
      await tester.tap(find.text('Luis Gómez'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.ledgerInactive), findsOneWidget);
      expect(find.text(AppStrings.ledgerInactiveHint), findsOneWidget);
      expect(find.text(AppStrings.ledgerRegisterAction), findsNothing);
      expect(find.text(AppStrings.ledgerRegisterFirstAction), findsNothing);

      await tester.tap(
        find.descendant(
          of: find.byType(SafeArea),
          matching: find.text(AppStrings.memberEditAction),
        ),
      );
      await tester.pumpAndSettle();

      expect(currentLocation(), AppRoutes.adminMemberEdition(3));
    });
  });

  group('paying for the whole family group', () {
    final family = <MemberModel>[
      buildMember(
        id: 1,
        firstName: 'Juan',
        lastName: 'Zárate',
        daysOverdue: 42,
        familyGroupId: 7,
      ),
      buildMember(
        id: 2,
        firstName: 'Ana',
        lastName: 'Zárate',
        daysOverdue: 42,
        familyGroupId: 7,
      ),
      buildMember(
          id: 3, firstName: 'Lucía', lastName: 'Zárate', familyGroupId: 7),
      buildMember(
        id: 4,
        firstName: 'Pedro',
        lastName: 'Zárate',
        status: MemberStatus.inactive,
        familyGroupId: 7,
      ),
    ];

    Future<void> openFamilyPaymentWith(
      WidgetTester tester,
      PaymentFakeDataSource Function(MemberRemoteDataSource members) payments, {
      List<MemberModel>? roster,
    }) async {
      await bootClub(
        tester,
        memberSource: MemberRosterDataSource(roster ?? family),
        payments: payments,
      );
      await openLedgerOf(tester, 'Juan Zárate');
      await tester.tap(find.text(AppStrings.ledgerRegisterAction));
      await tester.pumpAndSettle();

      final toggle = find.text(AppStrings.registerPaymentFamilyToggle);
      await tester.scrollUntilVisible(
        toggle,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
    }

    Future<RecordingPaymentSource> openFamilyPayment(
      WidgetTester tester,
    ) async {
      late RecordingPaymentSource source;
      await openFamilyPaymentWith(
        tester,
        (members) => source = RecordingPaymentSource(members: members),
      );

      return source;
    }

    testWidgets('shows what each member is charged, before confirming', (
      tester,
    ) async {
      await openFamilyPayment(tester);

      expect(
        find.text(
            AppStrings.registerPaymentFamilyCharges('septiembre de 2026')),
        findsNWidgets(2),
      );
      expect(
        find.text(AppStrings.registerPaymentFamilyNothingToCharge),
        findsOneWidget,
      );
      expect(
        find.text(
            AppStrings.registerPaymentFamilyInactiveLeftOut('Pedro Zárate')),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.registerPaymentReviewWithTotal(r'$30.000')),
        findsOneWidget,
      );
    });

    Future<void> retryFromNotice(WidgetTester tester, String total) async {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.retryAction));
      await tester.pumpAndSettle();
      final confirm = find.text(AppStrings.confirmPaymentAction(total));
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
    }

    void expectFamilySnackBar(int members, String total) {
      expect(currentLocation(), AppRoutes.adminMemberLedger(1));
      expect(
        find.text(
          AppStrings.familyPaymentRegistered(
            AppStrings.memberCount(members),
            total,
          ),
        ),
        findsOneWidget,
      );
    }

    testWidgets(
        'registers every member in a single request, paid by the member on '
        'screen', (tester) async {
      final source = await openFamilyPayment(tester);

      await tester.tap(
        find.text(AppStrings.registerPaymentReviewWithTotal(r'$30.000')),
      );
      await tester.pumpAndSettle();
      final skipped = find.ancestor(
        of: find.text('Lucía Zárate'),
        matching: find.byType(Row),
      );
      expect(
        find.descendant(
          of: skipped,
          matching: find.text(AppStrings.confirmPaymentSkipped),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(AppStrings.confirmPaymentAction(r'$30.000')));
      await tester.pumpAndSettle();

      expect(source.batches, hasLength(1));
      expect(source.drafts.map((draft) => draft.memberId), [1, 2]);
      expect(source.drafts.map((draft) => draft.paidByMemberId), [null, 1]);
      expectFamilySnackBar(2, r'$30.000');
    });

    testWidgets(
        'a payment the connection dropped registers nobody and sends everyone '
        'when retried', (tester) async {
      late DroppedBatchPaymentSource source;
      await openFamilyPaymentWith(
        tester,
        (members) => source = DroppedBatchPaymentSource(
          members: members,
          error: NetworkException('offline'),
        ),
      );

      await reviewAndConfirm(tester, r'$30.000');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(AppStrings.registerPaymentOfflineTitle),
        findsOneWidget,
      );
      expect(currentLocation(), isNot(AppRoutes.adminMemberLedger(1)));

      await retryFromNotice(tester, r'$30.000');

      expect(source.sent, 2);
      expectFamilySnackBar(2, r'$30.000');
    });

    testWidgets(
        'a month somebody else collected meanwhile registers nobody and '
        'updates what is charged', (tester) async {
      await openFamilyPaymentWith(
        tester,
        (members) => CollectedMonthPaymentSource(
          members: members,
          collectedMemberId: 2,
        ),
      );

      await reviewAndConfirm(tester, r'$30.000');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(AppStrings.familyPaymentMonthsCollected),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.registerPaymentReviewWithTotal(r'$15.000')),
        findsOneWidget,
      );

      await reviewAndConfirm(tester, r'$15.000');

      expectFamilySnackBar(1, r'$15.000');
    });

    testWidgets(
        'a relative who left the group is named and the payment goes again '
        'without them', (tester) async {
      final roster = [...family];
      await openFamilyPaymentWith(
        tester,
        (members) => LeavingRelativePaymentSource(
          members: members,
          roster: roster,
          leavingMemberId: 2,
        ),
        roster: roster,
      );

      await reviewAndConfirm(tester, r'$30.000');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(AppStrings.familyPaymentRelativesLeft('Ana Zárate', 1)),
        findsOneWidget,
      );

      await reviewAndConfirm(tester, r'$15.000');

      expectFamilySnackBar(1, r'$15.000');
    });

    testWidgets('a timeout that went through ends as registered', (
      tester,
    ) async {
      late DroppedBatchPaymentSource source;
      await openFamilyPaymentWith(
        tester,
        (members) => source = DroppedBatchPaymentSource(
          members: members,
          error: ResponseTimeoutException(),
          landsAnyway: true,
        ),
      );

      await reviewAndConfirm(tester, r'$30.000');

      expect(source.sent, 1);
      expectFamilySnackBar(2, r'$30.000');
    });

    testWidgets(
        'a timeout that did not go through asks to retry and registers once',
        (tester) async {
      late DroppedBatchPaymentSource source;
      await openFamilyPaymentWith(
        tester,
        (members) => source = DroppedBatchPaymentSource(
          members: members,
          error: ResponseTimeoutException(),
        ),
      );

      await reviewAndConfirm(tester, r'$30.000');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(AppStrings.registerPaymentUnconfirmedTitle),
        findsOneWidget,
      );

      await retryFromNotice(tester, r'$30.000');

      expect(source.sent, 2);
      expectFamilySnackBar(2, r'$30.000');
    });

    testWidgets('a relative left out is not charged', (tester) async {
      final source = await openFamilyPayment(tester);

      await tester.tap(find.widgetWithText(CheckboxListTile, 'Ana Zárate'));
      await tester.pumpAndSettle();
      await reviewAndConfirm(tester, r'$15.000');

      expect(source.drafts.map((draft) => draft.memberId), [1]);
    });
  });
}
