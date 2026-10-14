import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/domain/entities/member_ledger.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_draft.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_method.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_receipt.dart';
import 'package:club_management_app/features/payments/domain/failures/payment_failures.dart';
import 'package:club_management_app/features/payments/domain/usecases/load_member_ledger_use_case.dart';
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

void main() {
  late MockLoadMemberLedgerUseCase loadLedger;
  late MockRegisterPaymentUseCase registerPayment;
  late RegisterPaymentCubit cubit;

  final relative = buildLedgerMember(id: 2, firstName: 'María');
  final ledger = buildLedger(
    member: buildLedgerMember(familyGroupId: 7),
    familyMembers: [relative],
  );

  setUpAll(() {
    registerFallbackValue(
      const PaymentDraft(
        memberId: 1,
        months: [],
        amountCents: 0,
        method: PaymentMethod.cash,
      ),
    );
  });

  setUp(() {
    loadLedger = MockLoadMemberLedgerUseCase();
    registerPayment = MockRegisterPaymentUseCase();
    when(() => loadLedger(any())).thenAnswer((_) async => Right(ledger));
    cubit = RegisterPaymentCubit(
      loadLedger: loadLedger,
      registerPayment: registerPayment,
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

    test('asks again who paid when the relative left the group', () async {
      stubRegister(const Left(ValidationFailure()));
      await cubit.open(1);
      cubit.pickPayer(relative.id);

      await cubit.submit();

      expect(notice(), const PayerLeftGroupNotice());
      expect(form().payerId, isNull);
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

    test('says it was not registered when the history does not show it',
        () async {
      await submitTimingOut();

      await cubit.submit();

      expect(notice(), const PaymentTimedOutNotice());
      expect(form().selectedMonths, {const BillingMonth(2026, 9)});
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
}
