import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/domain/entities/family_payment_outcome.dart';
import 'package:club_management_app/features/payments/domain/entities/family_payment_request.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_draft.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_method.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_precheck.dart';
import 'package:club_management_app/features/payments/domain/failures/payment_failures.dart';
import 'package:club_management_app/features/payments/domain/repositories/payment_repository.dart';
import 'package:club_management_app/features/payments/domain/usecases/register_family_payment_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/payment_builders.dart';

class MockPaymentRepository extends Mock implements PaymentRepository {}

void main() {
  late MockPaymentRepository repository;
  late RegisterFamilyPaymentUseCase registerFamilyPayment;

  const september = BillingMonth(2026, 9);
  const october = BillingMonth(2026, 10);

  FamilyPaymentRequest requestFor({
    int? paidBy,
    List<int> relatives = const [2, 3],
  }) {
    return FamilyPaymentRequest(
      draft: PaymentDraft(
        memberId: 1,
        months: const [september, october],
        amountCents: feeCents,
        method: PaymentMethod.cash,
        paidByMemberId: paidBy,
      ),
      relativeIds: relatives,
    );
  }

  void stubHistories(
    int memberId,
    List<Either<Failure, PaymentPrecheck>> successiveReads,
  ) {
    var reads = 0;
    when(() => repository.loadPrecheck(memberId)).thenAnswer((_) async {
      final index = reads < successiveReads.length
          ? reads
          : successiveReads.length - 1;
      reads++;

      return successiveReads[index];
    });
  }

  void stubPrecheck(
    int memberId, {
    Set<BillingMonth> paid = const {},
    bool isActive = true,
  }) {
    stubHistories(memberId, [
      Right(PaymentPrecheck(isActive: isActive, paidMonths: paid)),
    ]);
  }

  void stubSend(Either<Failure, void> result) {
    when(() => repository.recordPayments(any()))
        .thenAnswer((_) async => result);
  }

  List<PaymentDraft> sentDrafts() =>
      verify(() => repository.recordPayments(captureAny())).captured.single
          as List<PaymentDraft>;

  setUpAll(() => registerFallbackValue(<PaymentDraft>[]));

  setUp(() {
    repository = MockPaymentRepository();
    registerFamilyPayment = RegisterFamilyPaymentUseCase(repository);
    for (final memberId in [1, 2, 3]) {
      stubPrecheck(memberId);
    }
    stubSend(const Right(null));
  });

  test('records the same months for the member and each relative in one '
      'request', () async {
    final outcome = await registerFamilyPayment(requestFor());

    expect(sentDrafts().map((draft) => draft.memberId), [1, 2, 3]);
    expect(
      outcome,
      const FamilyPaymentRegistered(
        months: {
          1: [september, october],
          2: [september, october],
          3: [september, october],
        },
      ),
    );
  });

  test('the member on screen paid for the relatives unless told otherwise',
      () async {
    await registerFamilyPayment(requestFor());

    expect(sentDrafts().map((draft) => draft.paidByMemberId), [null, 1, 1]);
  });

  test('a relative who paid figures as the payer of everybody else', () async {
    await registerFamilyPayment(requestFor(paidBy: 2));

    expect(sentDrafts().map((draft) => draft.paidByMemberId), [2, null, 2]);
  });

  test('skips the months a member already paid', () async {
    stubPrecheck(2, paid: {september});

    final outcome = await registerFamilyPayment(requestFor());

    expect(sentDrafts().map((draft) => draft.months), [
      [september, october],
      [october],
      [september, october],
    ]);
    expect((outcome as FamilyPaymentRegistered).months[2], [october]);
  });

  test('leaves out a member who already paid every month', () async {
    stubPrecheck(2, paid: {september, october});

    final outcome = await registerFamilyPayment(requestFor());

    expect(sentDrafts().map((draft) => draft.memberId), [1, 3]);
    expect((outcome as FamilyPaymentRegistered).months.keys, [1, 3]);
  });

  test('sends nothing when everybody already paid every month', () async {
    for (final memberId in [1, 2, 3]) {
      stubPrecheck(memberId, paid: {september, october});
    }

    final outcome = await registerFamilyPayment(requestFor());

    verifyNever(() => repository.recordPayments(any()));
    expect(outcome, const FamilyPaymentNothingToCharge());
  });

  test('a relative deactivated meanwhile is not charged and is reported',
      () async {
    stubPrecheck(2, isActive: false);

    final outcome = await registerFamilyPayment(requestFor());

    expect(sentDrafts().map((draft) => draft.memberId), [1, 3]);
    expect(outcome, isA<FamilyPaymentRegistered>());
    expect((outcome as FamilyPaymentRegistered).skippedIds, [2]);
  });

  test('a member deactivated meanwhile charges nobody in the group', () async {
    stubPrecheck(1, isActive: false);

    final outcome = await registerFamilyPayment(requestFor());

    verifyNever(() => repository.recordPayments(any()));
    expect(outcome, const FamilyPaymentRejected(InactiveMemberFailure()));
  });

  group('a history that cannot be read', () {
    test('sends nothing and reports why', () async {
      stubHistories(2, [const Left(NetworkFailure())]);

      final outcome = await registerFamilyPayment(requestFor());

      verifyNever(() => repository.recordPayments(any()));
      expect(outcome, const FamilyPaymentRejected(NetworkFailure()));
    });

    test('that timed out never claims the payment may have landed', () async {
      stubHistories(3, [const Left(ResponseTimeoutFailure())]);

      final outcome = await registerFamilyPayment(requestFor());

      verifyNever(() => repository.recordPayments(any()));
      expect(outcome, const FamilyPaymentRejected(ResponseTimeoutFailure()));
    });
  });

  group('a request the server refused', () {
    test('registers nobody when a payer left the group', () async {
      stubSend(const Left(ValidationFailure('Request rejected')));

      final outcome = await registerFamilyPayment(requestFor());

      expect(
        outcome,
        const FamilyPaymentRejected(ValidationFailure('Request rejected')),
      );
    });

    test('registers nobody when somebody else collected a month', () async {
      stubSend(const Left(ConflictFailure()));

      final outcome = await registerFamilyPayment(requestFor());

      expect(outcome, const FamilyPaymentRejected(ConflictFailure()));
    });

    test('registers nobody when the connection dropped', () async {
      stubSend(const Left(NetworkFailure()));

      final outcome = await registerFamilyPayment(requestFor());

      expect(outcome, const FamilyPaymentRejected(NetworkFailure()));
    });
  });

  group('a request nobody answered', () {
    final paidBoth = {september, october};

    setUp(() => stubSend(const Left(ResponseTimeoutFailure())));

    test('is registered when the history shows every month of every member',
        () async {
      for (final memberId in [1, 2, 3]) {
        stubHistories(memberId, [
          const Right(PaymentPrecheck(isActive: true, paidMonths: {})),
          Right(PaymentPrecheck(isActive: true, paidMonths: paidBoth)),
        ]);
      }

      final outcome = await registerFamilyPayment(requestFor());

      expect(outcome, isA<FamilyPaymentRegistered>());
      expect((outcome as FamilyPaymentRegistered).months.keys, [1, 2, 3]);
    });

    test('stays unconfirmed when a member does not show every month', () async {
      for (final memberId in [1, 3]) {
        stubHistories(memberId, [
          const Right(PaymentPrecheck(isActive: true, paidMonths: {})),
          Right(PaymentPrecheck(isActive: true, paidMonths: paidBoth)),
        ]);
      }

      final outcome = await registerFamilyPayment(requestFor());

      expect(outcome, isA<FamilyPaymentUnconfirmed>());
      expect((outcome as FamilyPaymentUnconfirmed).months.keys, [1, 2, 3]);
    });

    test('stays unconfirmed when the history cannot be read afterwards',
        () async {
      stubHistories(2, [
        const Right(PaymentPrecheck(isActive: true, paidMonths: {})),
        const Left(NetworkFailure()),
      ]);

      final outcome = await registerFamilyPayment(requestFor());

      expect(outcome, isA<FamilyPaymentUnconfirmed>());
    });

    test('remembers who was left out of the payment', () async {
      stubPrecheck(2, isActive: false);

      final outcome = await registerFamilyPayment(requestFor());

      expect((outcome as FamilyPaymentUnconfirmed).skippedIds, [2]);
    });
  });
}
