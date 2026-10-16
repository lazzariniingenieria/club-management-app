import 'dart:async';

import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/members/domain/usecases/watch_roster_changes_use_case.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/domain/entities/member_ledger.dart';
import 'package:club_management_app/features/payments/domain/usecases/load_member_ledger_use_case.dart';
import 'package:club_management_app/features/payments/domain/usecases/void_payment_use_case.dart';
import 'package:club_management_app/features/payments/domain/usecases/watch_payment_changes_use_case.dart';
import 'package:club_management_app/features/payments/presentation/cubit/member_ledger_cubit.dart';
import 'package:club_management_app/features/payments/presentation/cubit/member_ledger_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/payment_builders.dart';

class MockLoadMemberLedgerUseCase extends Mock
    implements LoadMemberLedgerUseCase {}

class MockVoidPaymentUseCase extends Mock implements VoidPaymentUseCase {}

class MockWatchRosterChangesUseCase extends Mock
    implements WatchRosterChangesUseCase {}

class MockWatchPaymentChangesUseCase extends Mock
    implements WatchPaymentChangesUseCase {}

void main() {
  late MockLoadMemberLedgerUseCase loadLedger;
  late MockVoidPaymentUseCase voidPayment;
  late StreamController<void> memberChanges;
  late StreamController<void> paymentChanges;
  late MemberLedgerCubit cubit;

  final ledger = buildLedger();

  setUp(() {
    loadLedger = MockLoadMemberLedgerUseCase();
    voidPayment = MockVoidPaymentUseCase();
    when(() => loadLedger(any())).thenAnswer((_) async => Right(ledger));
    memberChanges = StreamController<void>.broadcast();
    final watchRosterChanges = MockWatchRosterChangesUseCase();
    when(() => watchRosterChanges()).thenAnswer((_) => memberChanges.stream);
    paymentChanges = StreamController<void>.broadcast();
    final watchPaymentChanges = MockWatchPaymentChangesUseCase();
    when(() => watchPaymentChanges()).thenAnswer((_) => paymentChanges.stream);
    cubit = MemberLedgerCubit(
      loadLedger: loadLedger,
      voidPayment: voidPayment,
      watchRosterChanges: watchRosterChanges,
      watchPaymentChanges: watchPaymentChanges,
    );
  });

  tearDown(() async {
    await cubit.close();
    await memberChanges.close();
    await paymentChanges.close();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

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

  test('a void the server never answered is settled by the reload', () async {
    final voided = buildLedger(
      payments: [
        buildPayment(
          id: 2,
          month: const BillingMonth(2026, 8),
          voidedAt: DateTime.utc(2026, 10, 14),
        ),
        buildPayment(id: 1, month: const BillingMonth(2026, 7)),
      ],
    );
    stubVoid(const Left(ResponseTimeoutFailure()));
    await cubit.load(1);
    when(() => loadLedger(any())).thenAnswer((_) async => Right(voided));

    final failure = await cubit.voidPayment(ledger.payments.first);

    expect(failure, isNull);
    expect(cubit.state, MemberLedgerReady(voided));
  });

  test('a void the server never answered and did not apply is reported',
      () async {
    stubVoid(const Left(ResponseTimeoutFailure()));
    await cubit.load(1);

    final failure = await cubit.voidPayment(ledger.payments.first);

    expect(failure, isA<ResponseTimeoutFailure>());
    verify(() => loadLedger(1)).called(2);
  });

  group('a change to the member made elsewhere', () {
    test('reloads the ledger, so a member deactivated meanwhile shows it',
        () async {
      await cubit.load(1);
      final inactive = buildLedger(
        member: buildLedgerMember(status: MemberStatus.inactive),
      );
      when(() => loadLedger(any())).thenAnswer((_) async => Right(inactive));

      memberChanges.add(null);
      await settle();

      expect(cubit.state, MemberLedgerReady(inactive));
    });

    test('arriving during a load is not lost: one more load follows', () async {
      final firstLoad = Completer<Either<Failure, MemberLedger>>();
      when(() => loadLedger(any())).thenAnswer((_) => firstLoad.future);

      final loading = cubit.load(1);
      memberChanges.add(null);
      await settle();
      when(() => loadLedger(any())).thenAnswer((_) async => Right(ledger));
      firstLoad.complete(Right(ledger));
      await loading;

      verify(() => loadLedger(1)).called(2);
    });

    test('is no longer heard once the screen closes', () async {
      await cubit.close();

      expect(memberChanges.hasListener, isFalse);
    });
  });

  group('a payment recorded or voided elsewhere', () {
    test('reloads the ledger, so a payment that went through shows up',
        () async {
      await cubit.load(1);
      final paid = buildLedger(
        payments: [
          buildPayment(id: 3, month: const BillingMonth(2026, 9)),
          ...ledger.payments,
        ],
      );
      when(() => loadLedger(any())).thenAnswer((_) async => Right(paid));

      paymentChanges.add(null);
      await settle();

      verify(() => loadLedger(1)).called(2);
      expect(cubit.state, MemberLedgerReady(paid));
    });

    test('arriving during a load is not lost: one more load follows', () async {
      final firstLoad = Completer<Either<Failure, MemberLedger>>();
      when(() => loadLedger(any())).thenAnswer((_) => firstLoad.future);

      final loading = cubit.load(1);
      paymentChanges.add(null);
      paymentChanges.add(null);
      await settle();
      when(() => loadLedger(any())).thenAnswer((_) async => Right(ledger));
      firstLoad.complete(Right(ledger));
      await loading;

      verify(() => loadLedger(1)).called(2);
    });

    test('announced by a void from this screen reloads only once', () async {
      when(() => voidPayment(any(), reason: any(named: 'reason')))
          .thenAnswer((_) async {
        paymentChanges.add(null);

        return const Right(null);
      });
      await cubit.load(1);

      await cubit.voidPayment(ledger.payments.first);
      await settle();

      verify(() => loadLedger(1)).called(2);
    });

    test('is no longer heard once the screen closes', () async {
      await cubit.close();

      expect(paymentChanges.hasListener, isFalse);
    });
  });
}
