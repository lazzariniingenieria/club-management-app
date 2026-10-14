import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_draft.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_method.dart';
import 'package:club_management_app/features/payments/domain/failures/payment_failures.dart';
import 'package:club_management_app/features/payments/domain/repositories/payment_repository.dart';
import 'package:club_management_app/features/payments/domain/usecases/register_payment_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/payment_builders.dart';

class MockPaymentRepository extends Mock implements PaymentRepository {}

void main() {
  late MockPaymentRepository repository;
  late RegisterPaymentUseCase registerPayment;

  PaymentDraft draftFor(List<BillingMonth> months) {
    return PaymentDraft(
      memberId: 1,
      months: months,
      amountCents: feeCents,
      method: PaymentMethod.cash,
    );
  }

  setUpAll(() => registerFallbackValue(draftFor(const [])));

  setUp(() {
    repository = MockPaymentRepository();
    registerPayment = RegisterPaymentUseCase(repository);
    when(() => repository.loadLedger(any()))
        .thenAnswer((_) async => Right(buildLedger()));
    when(() => repository.recordPayment(any()))
        .thenAnswer((_) async => const Right(null));
  });

  test('records months that are still unpaid', () async {
    final draft = draftFor(
      const [BillingMonth(2026, 9), BillingMonth(2026, 10)],
    );

    final result = await registerPayment(draft);

    expect(result.isRight(), isTrue);
    verify(() => repository.recordPayment(draft)).called(1);
  });

  test('never sends a month that another payment already covers', () async {
    final result = await registerPayment(
      draftFor(const [BillingMonth(2026, 8), BillingMonth(2026, 9)]),
    );

    expect(
      result,
      const Left<Failure, void>(
        AlreadyPaidMonthsFailure([BillingMonth(2026, 8)]),
      ),
    );
    verifyNever(() => repository.recordPayment(any()));
  });

  test('a ledger that cannot be read stops the payment too', () async {
    when(() => repository.loadLedger(any()))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await registerPayment(
      draftFor(const [BillingMonth(2026, 9)]),
    );

    expect(result, const Left<Failure, void>(NetworkFailure()));
    verifyNever(() => repository.recordPayment(any()));
  });
}
