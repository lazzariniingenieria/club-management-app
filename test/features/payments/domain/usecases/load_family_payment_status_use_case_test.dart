import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_precheck.dart';
import 'package:club_management_app/features/payments/domain/repositories/payment_repository.dart';
import 'package:club_management_app/features/payments/domain/usecases/load_family_payment_status_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPaymentRepository extends Mock implements PaymentRepository {}

void main() {
  late MockPaymentRepository repository;
  late LoadFamilyPaymentStatusUseCase loadFamilyStatus;

  final paidSeptember = PaymentPrecheck(
    isActive: true,
    paidMonths: {const BillingMonth(2026, 9)},
  );
  const paidNothing = PaymentPrecheck(isActive: true, paidMonths: {});

  setUp(() {
    repository = MockPaymentRepository();
    loadFamilyStatus = LoadFamilyPaymentStatusUseCase(repository);
    when(() => repository.loadPrecheck(1))
        .thenAnswer((_) async => Right(paidSeptember));
    when(() => repository.loadPrecheck(2))
        .thenAnswer((_) async => const Right(paidNothing));
  });

  test('reads what each member already paid, without the whole ledger',
      () async {
    final result = await loadFamilyStatus([1, 2]);

    expect(result.getRight().toNullable(), {1: paidSeptember, 2: paidNothing});
    verifyNever(() => repository.loadLedger(any()));
  });

  test('one member that cannot be read fails the whole group', () async {
    when(() => repository.loadPrecheck(2))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await loadFamilyStatus([1, 2]);

    expect(result,
        const Left<Failure, Map<int, PaymentPrecheck>>(NetworkFailure()));
  });
}
