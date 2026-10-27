import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
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

  FamilyPaymentRequest requestFor(
      {int? paidBy, List<int> relatives = const [2, 3]}) {
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

  void stubPrecheck(
    int memberId, {
    Set<BillingMonth> paid = const {},
    bool isActive = true,
  }) {
    when(() => repository.loadPrecheck(memberId)).thenAnswer(
      (_) async => Right(PaymentPrecheck(isActive: isActive, paidMonths: paid)),
    );
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
    when(() => repository.recordPayments(any())).thenAnswer(
      (invocation) async => [
        for (final _ in invocation.positionalArguments.single as List)
          const Right<Failure, void>(null),
      ],
    );
  });

  test('records the same months for the member and each relative', () async {
    final outcome = await registerFamilyPayment(requestFor());

    expect(sentDrafts().map((draft) => draft.memberId), [1, 2, 3]);
    expect(outcome.isComplete, isTrue);
    expect(outcome.registered, {
      1: [september, october],
      2: [september, october],
      3: [september, october],
    });
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

    expect(sentDrafts()[1].months, [october]);
    expect(outcome.registered[2], [october]);
  });

  test('leaves out a member who already paid every month', () async {
    stubPrecheck(3, paid: {september, october});

    final outcome = await registerFamilyPayment(requestFor());

    expect(sentDrafts().map((draft) => draft.memberId), [1, 2]);
    expect(outcome.isComplete, isTrue);
    expect(outcome.registered.containsKey(3), isFalse);
  });

  test('a relative deactivated meanwhile is not charged and is reported',
      () async {
    stubPrecheck(2, isActive: false);

    final outcome = await registerFamilyPayment(requestFor());

    expect(sentDrafts().map((draft) => draft.memberId), [1, 3]);
    expect(outcome.failed, {2: const InactiveMemberFailure()});
  });

  test('a history that cannot be read keeps that member pending', () async {
    when(() => repository.loadPrecheck(3))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final outcome = await registerFamilyPayment(requestFor());

    expect(sentDrafts().map((draft) => draft.memberId), [1, 2]);
    expect(outcome.failed, {3: const NetworkFailure()});
  });

  test('a payment that timed out stays pending and may have landed', () async {
    when(() => repository.recordPayments(any())).thenAnswer(
      (_) async => const [
        Right(null),
        Left(ResponseTimeoutFailure()),
        Right(null),
      ],
    );

    final outcome = await registerFamilyPayment(requestFor());

    expect(outcome.registered.keys, [1, 3]);
    expect(outcome.mayHaveLanded, isTrue);
  });

  test('remembers the months a timed out payment may have recorded', () async {
    stubPrecheck(2, paid: {september});
    when(() => repository.recordPayments(any())).thenAnswer(
      (_) async => const [
        Right(null),
        Left(ResponseTimeoutFailure()),
        Right(null),
      ],
    );

    final outcome = await registerFamilyPayment(requestFor());

    expect(outcome.unconfirmed, {
      2: [october],
    });
  });

  test('a payment that failed for sure is not reported as unconfirmed',
      () async {
    when(() => repository.recordPayments(any())).thenAnswer(
      (_) async => const [
        Right(null),
        Left(NetworkFailure()),
        Right(null),
      ],
    );

    final outcome = await registerFamilyPayment(requestFor());

    expect(outcome.unconfirmed, isEmpty);
  });

  test('a conflict the history explains is not left pending', () async {
    var reads = 0;
    when(() => repository.loadPrecheck(2)).thenAnswer((_) async {
      reads++;
      final paid = reads == 1 ? <BillingMonth>{} : {september, october};

      return Right(PaymentPrecheck(isActive: true, paidMonths: paid));
    });
    when(() => repository.recordPayments(any())).thenAnswer(
      (_) async => const [
        Right(null),
        Left(ConflictFailure()),
        Right(null),
      ],
    );

    final outcome = await registerFamilyPayment(requestFor());

    expect(outcome.isComplete, isTrue);
    expect(outcome.registered.keys, [1, 3]);
  });

  test('a conflict the history does not explain stays pending', () async {
    when(() => repository.recordPayments(any())).thenAnswer(
      (_) async => const [
        Right(null),
        Left(ConflictFailure()),
        Right(null),
      ],
    );

    final outcome = await registerFamilyPayment(requestFor());

    expect(outcome.failed, {2: const ConflictFailure()});
  });
}
