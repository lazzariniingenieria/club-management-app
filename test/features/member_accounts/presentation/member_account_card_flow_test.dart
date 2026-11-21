import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/admins/data/datasources/admin_fake_data_source.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/club/data/datasources/club_fake_data_source.dart';
import 'package:club_management_app/features/member_accounts/data/datasources/member_account_fake_data_source.dart';
import 'package:club_management_app/features/member_accounts/data/models/member_account_model.dart';
import 'package:club_management_app/features/members/data/datasources/member_fake_data_source.dart';
import 'package:club_management_app/features/members/domain/entities/member_draft.dart';
import 'package:club_management_app/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

const int memberLinkedToAdmin = 1;
const int memberWithAccount = 2;
const int memberWithoutAccount = 4;
const int inactiveMember = 36;

class ScriptedAccountSource extends MemberAccountFakeDataSource {
  ScriptedAccountSource(MemberFakeDataSource members)
      : super(
          members: members,
          admins: AdminFakeDataSource(latency: Duration.zero),
          club: ClubFakeDataSource(latency: Duration.zero),
          latency: Duration.zero,
        );

  int failedLoadsLeft = 0;
  bool createdByAnotherAdmin = false;
  bool resetFindsNoAccount = false;
  int loads = 0;

  @override
  Future<MemberAccountModel?> fetchAccount(int memberId) async {
    loads++;
    if (failedLoadsLeft > 0) {
      failedLoadsLeft--;
      throw NetworkException('offline');
    }

    return super.fetchAccount(memberId);
  }

  @override
  Future<MemberAccountModel> resetPassword(
    int memberId,
    String newPassword,
  ) async {
    if (resetFindsNoAccount) {
      throw NotFoundException('member $memberId has no member account');
    }

    return super.resetPassword(memberId, newPassword);
  }

  @override
  Future<MemberAccountModel> createAccount(
      int memberId, String password) async {
    if (createdByAnotherAdmin) {
      await super.createAccount(memberId, password);
      throw ConflictException('member $memberId already has an account');
    }

    return super.createAccount(memberId, password);
  }
}

void main() {
  late MemberFakeDataSource members;

  final sectionLabel =
      find.text(AppStrings.memberAccountSectionLabel.toUpperCase());

  Future<void> openLedger(
    WidgetTester tester,
    int memberId, {
    ScriptedAccountSource? accounts,
    ClubFakeDataSource? club,
  }) async {
    await bootApp(
      tester,
      signedInAs: UserRole.admin,
      memberSource: members,
      memberAccountSource: accounts,
      clubSource: club,
    );
    di.sl<AppRouter>().router.push(AppRoutes.adminMemberLedger(memberId));
    await tester.pumpAndSettle();
  }

  Future<void> tapCardAction(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> savePassword(WidgetTester tester, String actionLabel) async {
    await tester.enterText(find.byType(TextField), 's3cr3t123');
    await tester.tap(find.widgetWithText(AppButton, actionLabel));
    await tester.pumpAndSettle();
  }

  setUp(() => members = MemberFakeDataSource(latency: Duration.zero));

  testWidgets('creates the account of a member that has a dni', (
    tester,
  ) async {
    await openLedger(tester, memberWithoutAccount);
    expect(find.text(AppStrings.memberAccountNone), findsOneWidget);

    await tapCardAction(tester, AppStrings.memberAccountCreateAction);
    expect(find.text(AppStrings.memberAccountCreateTitle), findsOneWidget);
    expect(find.text(AppStrings.memberAccountCreateNotice), findsOneWidget);
    await savePassword(tester, AppStrings.memberAccountCreateAction);

    expect(find.text(AppStrings.memberAccountCreated), findsOneWidget);
    expect(
      find.text(AppStrings.memberAccountSignsInWith('20.040.731')),
      findsOneWidget,
    );
    expect(find.text(AppStrings.memberAccountResetAction), findsOneWidget);
  });

  testWidgets('resets the password of a member account', (tester) async {
    await openLedger(tester, memberWithAccount);
    expect(
      find.text(AppStrings.memberAccountSignsInWith('20.013.577')),
      findsOneWidget,
    );

    await tapCardAction(tester, AppStrings.memberAccountResetAction);
    expect(find.text(AppStrings.memberAccountResetNotice), findsOneWidget);
    await savePassword(tester, AppStrings.memberAccountResetAction);

    expect(find.text(AppStrings.memberAccountResetDone), findsOneWidget);
  });

  testWidgets('a member without a dni is asked for one, with no action', (
    tester,
  ) async {
    await tester.runAsync(
      () => members.updateMember(
        memberWithoutAccount,
        const MemberDraft(firstName: 'Lucía', lastName: 'Álvarez', dni: ''),
      ),
    );

    await openLedger(tester, memberWithoutAccount);

    expect(find.text(AppStrings.memberAccountNeedsDni), findsOneWidget);
    expect(find.text(AppStrings.memberAccountCreateAction), findsNothing);
  });

  testWidgets('a member who is an admin signs in with that account', (
    tester,
  ) async {
    await openLedger(tester, memberLinkedToAdmin);

    expect(find.text(AppStrings.memberAccountAdmin), findsOneWidget);
    expect(find.text(AppStrings.memberAccountResetAction), findsNothing);
    expect(find.text(AppStrings.memberAccountCreateAction), findsNothing);
  });

  testWidgets('a deactivated member without an account shows no card', (
    tester,
  ) async {
    await openLedger(tester, inactiveMember);

    expect(find.text(AppStrings.ledgerInactiveHint), findsOneWidget);
    expect(sectionLabel, findsNothing);
  });

  testWidgets('a club with the member app off shows no card', (tester) async {
    await openLedger(
      tester,
      memberWithoutAccount,
      club: ClubFakeDataSource(latency: Duration.zero, memberAppEnabled: false),
    );

    expect(find.text(AppStrings.familyGroupBuildAction), findsOneWidget);
    expect(sectionLabel, findsNothing);
  });

  testWidgets('an account that fails to load can be retried in the card', (
    tester,
  ) async {
    final accounts = ScriptedAccountSource(members)..failedLoadsLeft = 1;
    await openLedger(tester, memberWithAccount, accounts: accounts);

    expect(find.text(AppStrings.memberAccountLoadFailed), findsOneWidget);
    expect(find.text(AppStrings.memberAccountLoadOffline), findsOneWidget);
    expect(find.text(AppStrings.ledgerRegisterAction), findsOneWidget);

    await tapCardAction(tester, AppStrings.retryAction);

    expect(
      find.text(AppStrings.memberAccountSignsInWith('20.013.577')),
      findsOneWidget,
    );
  });

  testWidgets('a conflict is explained and the card reloads when closing', (
    tester,
  ) async {
    final accounts = ScriptedAccountSource(members)
      ..createdByAnotherAdmin = true;
    await openLedger(tester, memberWithoutAccount, accounts: accounts);

    await tapCardAction(tester, AppStrings.memberAccountCreateAction);
    await savePassword(tester, AppStrings.memberAccountCreateAction);

    expect(find.text(AppStrings.memberAccountConflict), findsOneWidget);

    await tester.tap(find.text(AppStrings.cancelAction));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.memberAccountConflict), findsNothing);
    expect(
      find.text(AppStrings.memberAccountSignsInWith('20.040.731')),
      findsOneWidget,
    );
  });

  testWidgets('a reset of an account that is gone reloads the card', (
    tester,
  ) async {
    final accounts = ScriptedAccountSource(members)..resetFindsNoAccount = true;
    await openLedger(tester, memberWithAccount, accounts: accounts);

    await tapCardAction(tester, AppStrings.memberAccountResetAction);
    await savePassword(tester, AppStrings.memberAccountResetAction);

    expect(find.text(AppStrings.saveFailedServer), findsOneWidget);
    final loadsBeforeClosing = accounts.loads;

    await tester.tap(find.text(AppStrings.cancelAction));
    await tester.pumpAndSettle();

    expect(accounts.loads, loadsBeforeClosing + 1);
  });
}
