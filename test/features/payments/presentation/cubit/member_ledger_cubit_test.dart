import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/payments/domain/usecases/load_member_ledger_use_case.dart';
import 'package:club_management_app/features/payments/domain/usecases/void_payment_use_case.dart';
import 'package:club_management_app/features/payments/presentation/cubit/member_ledger_cubit.dart';
import 'package:club_management_app/features/payments/presentation/cubit/member_ledger_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/payment_builders.dart';

class MockLoadMemberLedgerUseCase extends Mock
    implements LoadMemberLedgerUseCase {}

class MockVoidPaymentUseCase extends Mock implements VoidPaymentUseCase {}

void main() {
  late MockLoadMemberLedgerUseCase loadLedger;
  late MockVoidPaymentUseCase voidPayment;
  late MemberLedgerCubit cubit;

  final ledger = buildLedger();

  setUp(() {
    loadLedger = MockLoadMemberLedgerUseCase();
    voidPayment = MockVoidPaymentUseCase();
    when(() => loadLedger(any())).thenAnswer((_) async => Right(ledger));
    cubit = MemberLedgerCubit(loadLedger: loadLedger, voidPayment: voidPayment);
  });

  tearDown(() => cubit.close());

  void stubVoid(Either<Failure, void> result) {
    when(() => voidPayment(any(), reason: any(named: 'reason')))
        .thenAnswer((_) async => result);
  }

  test('starts loading so the screen opens on its skeleton', () {
    expect(cubit.state, const MemberLedgerLoading());
  });

  test('shows the ledger once it loads', () async {
    await cubit.load(1);

    expect(cubit.state, MemberLedgerReady(ledger));
  });

  test('tells an offline device apart from a server failure', () async {
    when(() => loadLedger(any()))
        .thenAnswer((_) async => const Left(NetworkFailure()));
    await cubit.load(1);
    expect(cubit.state, const MemberLedgerFailure(isOffline: true));

    when(() => loadLedger(any()))
        .thenAnswer((_) async => const Left(ServerFailure()));
    await cubit.reload();
    expect(cubit.state, const MemberLedgerFailure(isOffline: false));
  });

  test('explains a member that is no longer in the club', () async {
    when(() => loadLedger(any()))
        .thenAnswer((_) async => const Left(NotFoundFailure()));

    await cubit.load(1);

    expect(cubit.state, const MemberLedgerMissing());
  });

  test('voiding reloads the ledger so the mora is recalculated', () async {
    stubVoid(const Right(null));
    await cubit.load(1);

    final failure = await cubit.voidPayment(
      ledger.payments.first,
      reason: 'Error',
    );

    expect(failure, isNull);
    verify(() => voidPayment(ledger.payments.first.id, reason: 'Error'))
        .called(1);
    verify(() => loadLedger(1)).called(2);
  });

  test('a payment voided by someone else also reloads the ledger', () async {
    stubVoid(const Left(ConflictFailure()));
    await cubit.load(1);

    final failure = await cubit.voidPayment(ledger.payments.first);

    expect(failure, isA<ConflictFailure>());
    verify(() => loadLedger(1)).called(2);
  });

  test('a void that never reached the server keeps the ledger as it was',
      () async {
    stubVoid(const Left(NetworkFailure()));
    await cubit.load(1);

    final failure = await cubit.voidPayment(ledger.payments.first);

    expect(failure, isA<NetworkFailure>());
    verify(() => loadLedger(1)).called(1);
    expect(cubit.state, MemberLedgerReady(ledger));
  });
}
