import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
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
}
