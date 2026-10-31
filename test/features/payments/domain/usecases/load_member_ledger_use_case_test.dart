import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/club/domain/entities/club.dart';
import 'package:club_management_app/features/club/domain/repositories/club_repository.dart';
import 'package:club_management_app/features/payments/domain/repositories/payment_repository.dart';
import 'package:club_management_app/features/payments/domain/usecases/load_member_ledger_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/payment_builders.dart';

class MockPaymentRepository extends Mock implements PaymentRepository {}

class MockClubRepository extends Mock implements ClubRepository {}

void main() {
  late MockPaymentRepository payments;
  late MockClubRepository club;
  late LoadMemberLedgerUseCase loadLedger;

  final ledgerWithoutFee = buildLedger(monthlyFeeCents: null);

  setUp(() {
    payments = MockPaymentRepository();
    club = MockClubRepository();
    loadLedger = LoadMemberLedgerUseCase(payments: payments, club: club);
    when(() => payments.loadLedger(1))
        .thenAnswer((_) async => Right(ledgerWithoutFee));
  });

  test('the fee of reference comes from the club', () async {
    when(() => club.loadClub()).thenAnswer(
      (_) async => const Right(Club(id: 1, name: 'C', monthlyFeeCents: 1600000)),
    );

    final ledger = (await loadLedger(1)).getRight().toNullable()!;

    expect(ledger.monthlyFeeCents, 1600000);
    expect(ledger.payments, ledgerWithoutFee.payments);
  });

  test('a club without a fee leaves the amount empty', () async {
    when(() => club.loadClub())
        .thenAnswer((_) async => const Right(Club(id: 1, name: 'C')));

    final ledger = (await loadLedger(1)).getRight().toNullable()!;

    expect(ledger.monthlyFeeCents, isNull);
  });

  test('a failing club read does not block the ledger', () async {
    when(() => club.loadClub())
        .thenAnswer((_) async => const Left(ServerFailure()));

    final ledger = (await loadLedger(1)).getRight().toNullable()!;

    expect(ledger.monthlyFeeCents, isNull);
    expect(ledger.member, ledgerWithoutFee.member);
  });

  test('a failing ledger is reported as is', () async {
    when(() => payments.loadLedger(1))
        .thenAnswer((_) async => const Left(NetworkFailure()));
    when(() => club.loadClub())
        .thenAnswer((_) async => const Right(Club(id: 1, name: 'C')));

    expect(await loadLedger(1), const Left(NetworkFailure()));
  });
}
