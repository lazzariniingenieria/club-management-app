import 'dart:async';

import 'package:club_management_app/core/errors/failure_messages.dart';
import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/domain/entities/family_payment_outcome.dart';
import 'package:club_management_app/features/payments/domain/entities/family_payment_request.dart';
import 'package:club_management_app/features/payments/domain/entities/member_ledger.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_draft.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_method.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_precheck.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_receipt.dart';
import 'package:club_management_app/features/payments/domain/failures/payment_failures.dart';
import 'package:club_management_app/features/payments/domain/usecases/load_family_payment_status_use_case.dart';
import 'package:club_management_app/features/payments/domain/usecases/load_member_ledger_use_case.dart';
import 'package:club_management_app/features/payments/domain/usecases/register_family_payment_use_case.dart';
import 'package:club_management_app/features/payments/domain/usecases/register_payment_use_case.dart';
import 'package:club_management_app/features/payments/presentation/cubit/payment_form.dart';
import 'package:club_management_app/features/payments/presentation/cubit/register_payment_cubit.dart';
import 'package:club_management_app/features/payments/presentation/cubit/register_payment_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/payment_builders.dart';

class MockLoadMemberLedgerUseCase extends Mock
    implements LoadMemberLedgerUseCase {}

class MockRegisterPaymentUseCase extends Mock
    implements RegisterPaymentUseCase {}

class MockLoadFamilyPaymentStatusUseCase extends Mock
    implements LoadFamilyPaymentStatusUseCase {}

class MockRegisterFamilyPaymentUseCase extends Mock
    implements RegisterFamilyPaymentUseCase {}

void main() {
  late MockLoadMemberLedgerUseCase loadLedger;
  late MockRegisterPaymentUseCase registerPayment;
  late MockLoadFamilyPaymentStatusUseCase loadFamilyStatus;
  late MockRegisterFamilyPaymentUseCase registerFamilyPayment;
  late RegisterPaymentCubit cubit;

  final relative = buildLedgerMember(id: 2, firstName: 'María');
  final ledger = buildLedger(
    member: buildLedgerMember(familyGroupId: 7),
    familyMembers: [relative],
  );

  setUpAll(() {
    const draft = PaymentDraft(
      memberId: 1,
      months: [],
      amountCents: 0,
      method: PaymentMethod.cash,
    );
    registerFallbackValue(draft);
    registerFallbackValue(
      const FamilyPaymentRequest(draft: draft, relativeIds: []),
    );
  });

  setUp(() {
    loadLedger = MockLoadMemberLedgerUseCase();
    registerPayment = MockRegisterPaymentUseCase();
    loadFamilyStatus = MockLoadFamilyPaymentStatusUseCase();
    registerFamilyPayment = MockRegisterFamilyPaymentUseCase();
    when(() => loadLedger(any())).thenAnswer((_) async => Right(ledger));
    cubit = RegisterPaymentCubit(
      loadLedger: loadLedger,
      registerPayment: registerPayment,
      loadFamilyStatus: loadFamilyStatus,
      registerFamilyPayment: registerFamilyPayment,
      clock: () => DateTime(2026, 10, 14),
    );
  });

  tearDown(() => cubit.close());

  PaymentForm form() => (cubit.state as RegisterPaymentEditing).form;

  RegisterPaymentNotice? notice() =>
      (cubit.state as RegisterPaymentEditing).notice;

  void stubRegister(Either<Failure, void> result) {
    when(() => registerPayment(any())).thenAnswer((_) async => result);
  }

  group('opening the form', () {
    test('suggests the month after the last one paid', () async {
      await cubit.open(1);

      expect(form().selectedMonths, {const BillingMonth(2026, 9)});
      expect(form().visibleYear, 2026);
    });

    test('starts with the fee of the club, cash and the member paying',
        () async {
      await cubit.open(1);

      expect(form().amountCents, feeCents);
      expect(form().method, PaymentMethod.cash);
      expect(form().payerId, isNull);
    });

    test('starts empty when the club has no fee', () async {
      when(() => loadLedger(any())).thenAnswer(
        (_) async => Right(buildLedger(monthlyFeeCents: null)),
      );

      await cubit.open(1);

      expect(form().amountCents, isNull);
      expect(form().canReview, isFalse);
    });

    test('takes a fee with cents as it comes', () async {
      when(() => loadLedger(any())).thenAnswer(
        (_) async => Right(buildLedger(monthlyFeeCents: 1500050)),
      );

      await cubit.open(1);

      expect(form().amountCents, 1500050);
    });

    test('refuses an inactive member, who cannot pay', () async {
      when(() => loadLedger(any())).thenAnswer(
        (_) async => Right(
          buildLedger(
            member: buildLedgerMember(status: MemberStatus.inactive),
          ),
        ),
      );

      await cubit.open(1);

      expect(cubit.state, const RegisterPaymentUnavailable(isInactive: true));
    });

    test('explains a member that is no longer in the club', () async {
      when(() => loadLedger(any()))
          .thenAnswer((_) async => const Left(NotFoundFailure()));

      await cubit.open(1);

      expect(cubit.state, const RegisterPaymentUnavailable(isMissing: true));
    });
  });

  group('editing', () {
    test('the total is the amount of one month times the months', () async {
      await cubit.open(1);

      cubit.toggleMonth(const BillingMonth(2026, 10));
      cubit.changeAmount('12.000');

      expect(form().selectedMonths, hasLength(2));
      expect(form().totalCents, 2400000);
    });

    test('takes an amount with cents, as the API does', () async {
      await cubit.open(1);

      cubit.changeAmount('12.000,5');

      expect(form().amountCents, 1200050);
    });

    test('a month already paid cannot be chosen', () async {
      await cubit.open(1);

      cubit.toggleMonth(const BillingMonth(2026, 8));

      expect(form().isSelected(const BillingMonth(2026, 8)), isFalse);
    });

    test('tapping a chosen month takes it out', () async {
      await cubit.open(1);

      cubit.toggleMonth(const BillingMonth(2026, 9));

      expect(form().selectedMonths, isEmpty);
      expect(form().canReview, isFalse);
    });

    test('never shows a year before the member joined', () async {
      await cubit.open(1);

      cubit.showYear(2001);

      expect(form().visibleYear, 2024);
    });
  });

  group('submitting', () {
    test('ends with a receipt of the months and the total', () async {
      stubRegister(const Right(null));
      await cubit.open(1);
      cubit.toggleMonth(const BillingMonth(2026, 10));

      await cubit.submit();

      expect(
        cubit.state,
        const RegisterPaymentRegistered(
          PaymentReceipt(
            memberId: 1,
            months: [BillingMonth(2026, 9), BillingMonth(2026, 10)],
            totalCents: 3000000,
          ),
        ),
      );
    });

    test('sends the relative who paid', () async {
      stubRegister(const Right(null));
      await cubit.open(1);
      cubit.pickPayer(relative.id);

      await cubit.submit();

      final draft = verify(() => registerPayment(captureAny())).captured.single
          as PaymentDraft;
      expect(draft.paidByMemberId, relative.id);
    });

    test('keeps everything loaded when the connection drops', () async {
      stubRegister(const Left(NetworkFailure()));
      await cubit.open(1);
      cubit.pickMethod(PaymentMethod.transfer);

      await cubit.submit();

      expect(notice(), const OfflineNotice());
      expect(form().method, PaymentMethod.transfer);
      expect(form().selectedMonths, {const BillingMonth(2026, 9)});
    });

    test('drops a month somebody else paid meanwhile and says so', () async {
      stubRegister(
        const Left(AlreadyPaidMonthsFailure([BillingMonth(2026, 9)])),
      );
      await cubit.open(1);
      cubit.toggleMonth(const BillingMonth(2026, 10));

      await cubit.submit();

      expect(
        notice(),
        const MonthsAlreadyPaidNotice([BillingMonth(2026, 9)]),
      );
      expect(form().selectedMonths, {const BillingMonth(2026, 10)});
    });

    group('a rejected payment paid by a relative', () {
      Future<void> submitRejected() async {
        stubRegister(const Left(ValidationFailure()));
        await cubit.open(1);
        cubit.pickPayer(relative.id);
      }

      test('asks again who paid when the relative left the group', () async {
        await submitRejected();
        when(() => loadLedger(any())).thenAnswer(
          (_) async => Right(
            buildLedger(member: buildLedgerMember(familyGroupId: 7)),
          ),
        );

        await cubit.submit();

        expect(notice(), const PayerLeftGroupNotice());
        expect(form().payerId, isNull);
      });

      test('keeps the relative and shows the error when they are still there',
          () async {
        await submitRejected();

        await cubit.submit();

        expect(
          notice(),
          SubmitFailedNotice(const ValidationFailure().userMessage),
        );
        expect(form().payerId, relative.id);
      });

      test('keeps the relative when the group cannot be checked', () async {
        await submitRejected();
        when(() => loadLedger(any()))
            .thenAnswer((_) async => const Left(NetworkFailure()));

        await cubit.submit();

        expect(
          notice(),
          SubmitFailedNotice(const ValidationFailure().userMessage),
        );
        expect(form().payerId, relative.id);
      });
    });

    test('ignores a second submit while the first one is in flight', () async {
      stubRegister(const Right(null));
      await cubit.open(1);

      await Future.wait([cubit.submit(), cubit.submit()]);

      verify(() => registerPayment(any())).called(1);
    });
  });

  group('a submit the server never answered', () {
    MemberLedger ledgerPaying(List<BillingMonth> months) => buildLedger(
          payments: [
            for (final (index, month) in months.indexed)
              buildPayment(id: 10 + index, month: month),
            buildPayment(id: 2, month: const BillingMonth(2026, 8)),
          ],
        );

    Future<void> submitTimingOut() async {
      stubRegister(const Left(ResponseTimeoutFailure()));
      await cubit.open(1);
    }

    test('ends as registered when the history shows it went through', () async {
      await submitTimingOut();
      when(() => loadLedger(any())).thenAnswer(
        (_) async => Right(ledgerPaying(const [BillingMonth(2026, 9)])),
      );

      await cubit.submit();

      expect(cubit.state, isA<RegisterPaymentRegistered>());
    });

    test('admits it does not know when the history does not show it yet',
        () async {
      await submitTimingOut();

      await cubit.submit();

      expect(notice(), const PaymentUnconfirmedNotice());
      expect(form().selectedMonths, {const BillingMonth(2026, 9)});
    });

    test('a retry after the history did not show it ends as registered',
        () async {
      await submitTimingOut();
      await cubit.submit();
      stubRegister(
        const Left(AlreadyPaidMonthsFailure([BillingMonth(2026, 9)])),
      );

      await cubit.submit();

      expect(cubit.state, isA<RegisterPaymentRegistered>());
    });

    test('drops the months the history shows and still doubts the rest',
        () async {
      await submitTimingOut();
      cubit.toggleMonth(const BillingMonth(2026, 10));
      when(() => loadLedger(any())).thenAnswer(
        (_) async => Right(ledgerPaying(const [BillingMonth(2026, 9)])),
      );
      await cubit.submit();

      expect(
        notice(),
        const MonthsAlreadyPaidNotice([BillingMonth(2026, 9)]),
      );
      expect(form().selectedMonths, {const BillingMonth(2026, 10)});

      stubRegister(
        const Left(AlreadyPaidMonthsFailure([BillingMonth(2026, 10)])),
      );
      await cubit.submit();

      expect(cubit.state, isA<RegisterPaymentRegistered>());
    });

    test('admits it does not know when the history cannot be read', () async {
      await submitTimingOut();
      when(() => loadLedger(any()))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      await cubit.submit();

      expect(notice(), const PaymentUnconfirmedNotice());
    });

    test('a retry that finds those months paid ends as registered', () async {
      await submitTimingOut();
      when(() => loadLedger(any()))
          .thenAnswer((_) async => const Left(NetworkFailure()));
      await cubit.submit();
      stubRegister(
        const Left(AlreadyPaidMonthsFailure([BillingMonth(2026, 9)])),
      );

      await cubit.submit();

      expect(cubit.state, isA<RegisterPaymentRegistered>());
    });

    group('a retry after editing the form', () {
      Future<void> leaveUnconfirmed() async {
        await submitTimingOut();
        when(() => loadLedger(any()))
            .thenAnswer((_) async => const Left(NetworkFailure()));
        await cubit.submit();
        stubRegister(
          const Left(AlreadyPaidMonthsFailure([BillingMonth(2026, 9)])),
        );
      }

      Future<void> expectNotTakenAsRegistered() async {
        await cubit.submit();

        expect(cubit.state, isA<RegisterPaymentEditing>());
        expect(
          notice(),
          const MonthsAlreadyPaidNotice([BillingMonth(2026, 9)]),
        );
      }

      test('with another amount is not taken as the payment that went through',
          () async {
        await leaveUnconfirmed();
        cubit.changeAmount('12.000');

        await expectNotTakenAsRegistered();
      });

      test('with another method is not taken as the payment that went through',
          () async {
        await leaveUnconfirmed();
        cubit.pickMethod(PaymentMethod.transfer);

        await expectNotTakenAsRegistered();
      });

      test('with another payer is not taken as the payment that went through',
          () async {
        await leaveUnconfirmed();
        cubit.pickPayer(relative.id);

        await expectNotTakenAsRegistered();
      });

      test('that only looked at another year still ends as registered',
          () async {
        await leaveUnconfirmed();
        cubit.showYear(2025);

        await cubit.submit();

        expect(cubit.state, isA<RegisterPaymentRegistered>());
      });
    });

    test('a lost connection is still told apart from a timeout', () async {
      stubRegister(const Left(NetworkFailure()));
      await cubit.open(1);

      await cubit.submit();

      expect(notice(), const OfflineNotice());
    });
  });

  test('a member deactivated meanwhile ends the form', () async {
    stubRegister(const Left(InactiveMemberFailure()));
    await cubit.open(1);

    await cubit.submit();

    expect(cubit.state, const RegisterPaymentUnavailable(isInactive: true));
  });

  group('paying for the whole family group', () {
    const september = BillingMonth(2026, 9);
    const october = BillingMonth(2026, 10);

    PaymentPrecheck paid(Set<BillingMonth> months) =>
        PaymentPrecheck(isActive: true, paidMonths: months);

    void stubStatuses({Set<BillingMonth> relativePaid = const {}}) {
      when(() => loadFamilyStatus(any())).thenAnswer(
        (_) async => Right({1: paid(const {}), 2: paid(relativePaid)}),
      );
    }

    void stubOutcome(FamilyPaymentOutcome outcome) {
      when(() => registerFamilyPayment(any())).thenAnswer((_) async => outcome);
    }

    Future<void> openForFamily() async {
      await cubit.open(1);
      await cubit.payForFamily(enabled: true);
    }

    test('reads what the member and each active relative already paid',
        () async {
      stubStatuses();

      await openForFamily();

      verify(() => loadFamilyStatus([1, 2])).called(1);
      expect(form().family?.isReady, isTrue);
    });

    test('the payment cannot be reviewed while the group is read', () async {
      final statuses = Completer<Either<Failure, Map<int, PaymentPrecheck>>>();
      when(() => loadFamilyStatus(any())).thenAnswer((_) => statuses.future);
      await cubit.open(1);

      final turningOn = cubit.payForFamily(enabled: true);

      expect(form().canReview, isFalse);
      statuses.complete(Right({1: paid(const {}), 2: paid(const {})}));
      await turningOn;
      expect(form().canReview, isTrue);
    });

    test('charges each member only the months they still owe', () async {
      stubStatuses(relativePaid: {september});
      await openForFamily();
      cubit.toggleMonth(october);

      expect(form().monthsFor(relative), [october]);
      expect(form().feeCount, 3);
      expect(form().totalCents, 3 * feeCents);
    });

    test('a relative left out is neither charged nor sent', () async {
      stubStatuses();
      stubOutcome(
        const FamilyPaymentOutcome(
          registered: {
            1: [september],
          },
        ),
      );
      await openForFamily();

      cubit.toggleRelative(relative.id);
      expect(form().feeCount, 1);
      await cubit.submit();

      final request = verify(() => registerFamilyPayment(captureAny()))
          .captured
          .single as FamilyPaymentRequest;
      expect(request.relativeIds, isEmpty);
    });

    test('leaves inactive relatives out from the start', () async {
      final inactive = buildLedgerMember(
        id: 3,
        firstName: 'Luis',
        status: MemberStatus.inactive,
      );
      when(() => loadLedger(any())).thenAnswer(
        (_) async => Right(
          buildLedger(
            member: buildLedgerMember(familyGroupId: 7),
            familyMembers: [relative, inactive],
          ),
        ),
      );
      stubStatuses();

      await openForFamily();

      verify(() => loadFamilyStatus([1, 2])).called(1);
      expect(form().chargedMembers.map((member) => member.id), [1, 2]);
    });

    test('a group that cannot be read offers to read it again', () async {
      when(() => loadFamilyStatus(any()))
          .thenAnswer((_) async => const Left(NetworkFailure()));
      await openForFamily();
      expect(form().family?.failedToLoad, isTrue);

      stubStatuses();
      await cubit.reloadFamilyStatus();

      expect(form().family?.isReady, isTrue);
    });

    test('turning it off pays only for the member again', () async {
      stubStatuses();
      stubRegister(const Right(null));
      await openForFamily();

      await cubit.payForFamily(enabled: false);
      await cubit.submit();

      verify(() => registerPayment(any())).called(1);
      verifyNever(() => registerFamilyPayment(any()));
    });

    test('ends with a receipt that counts every member charged', () async {
      stubStatuses();
      stubOutcome(
        const FamilyPaymentOutcome(
          registered: {
            1: [september],
            2: [september],
          },
        ),
      );
      await openForFamily();

      await cubit.submit();

      expect(
        cubit.state,
        const RegisterPaymentRegistered(
          PaymentReceipt(
            memberId: 1,
            months: [september],
            totalCents: 2 * feeCents,
            familyMemberCount: 2,
          ),
        ),
      );
    });

    test('a payment left half done says who is missing and rereads the group',
        () async {
      stubStatuses();
      stubOutcome(
        const FamilyPaymentOutcome(
          registered: {
            1: [september],
          },
          failed: {2: NetworkFailure()},
        ),
      );
      await openForFamily();

      await cubit.submit();

      expect(
        notice(),
        const FamilyPaymentIncompleteNotice(
          registeredIds: [1],
          pendingIds: [2],
          mayHaveLanded: false,
        ),
      );
      verify(() => loadFamilyStatus(any())).called(2);
    });

    test('a timeout tells the admin the payment may have gone through',
        () async {
      stubStatuses();
      stubOutcome(
        const FamilyPaymentOutcome(failed: {2: ResponseTimeoutFailure()}),
      );
      await openForFamily();

      await cubit.submit();

      final incomplete = notice() as FamilyPaymentIncompleteNotice;
      expect(incomplete.mayHaveLanded, isTrue);
    });

    test('the receipt after a retry counts the members paid before', () async {
      stubStatuses();
      stubOutcome(
        const FamilyPaymentOutcome(
          registered: {
            1: [september],
          },
          failed: {2: NetworkFailure()},
        ),
      );
      await openForFamily();
      await cubit.submit();

      stubOutcome(
        const FamilyPaymentOutcome(
          registered: {
            2: [september],
          },
        ),
      );
      await cubit.submit();

      final receipt = (cubit.state as RegisterPaymentRegistered).receipt;
      expect(receipt.familyMemberCount, 2);
      expect(receipt.totalCents, 2 * feeCents);
    });

    test('says so when somebody else already paid every month', () async {
      stubStatuses();
      stubOutcome(const FamilyPaymentOutcome());
      await openForFamily();

      await cubit.submit();

      expect(notice(), const FamilyAlreadyPaidNotice());
    });

    test('a member deactivated meanwhile ends the form', () async {
      stubStatuses();
      stubOutcome(
        const FamilyPaymentOutcome(failed: {1: InactiveMemberFailure()}),
      );
      await openForFamily();

      await cubit.submit();

      expect(cubit.state, const RegisterPaymentUnavailable(isInactive: true));
    });
  });
}
