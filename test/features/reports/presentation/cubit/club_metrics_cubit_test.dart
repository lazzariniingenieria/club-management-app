import 'dart:async';

import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/members/domain/usecases/watch_roster_changes_use_case.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/domain/usecases/watch_payment_changes_use_case.dart';
import 'package:club_management_app/features/reports/domain/entities/club_metrics.dart';
import 'package:club_management_app/features/reports/domain/usecases/load_club_metrics_use_case.dart';
import 'package:club_management_app/features/reports/presentation/cubit/club_metrics_cubit.dart';
import 'package:club_management_app/features/reports/presentation/cubit/club_metrics_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLoadMetrics extends Mock implements LoadClubMetricsUseCase {}

class MockWatchRoster extends Mock implements WatchRosterChangesUseCase {}

class MockWatchPayments extends Mock implements WatchPaymentChangesUseCase {}

void main() {
  late MockLoadMetrics loadMetrics;
  late StreamController<void> paymentChanges;
  late ClubMetricsCubit cubit;

  const october = BillingMonth(2026, 10);
  const september = BillingMonth(2026, 9);
  const empty = ClubMetrics(payments: [], members: []);

  ClubMetricsReady ready() => cubit.state as ClubMetricsReady;

  setUp(() {
    loadMetrics = MockLoadMetrics();
    paymentChanges = StreamController<void>.broadcast();
    final watchRoster = MockWatchRoster();
    final watchPayments = MockWatchPayments();
    when(() => watchRoster()).thenAnswer((_) => const Stream.empty());
    when(() => watchPayments()).thenAnswer((_) => paymentChanges.stream);
    when(() => loadMetrics()).thenAnswer((_) async => const Right(empty));
    cubit = ClubMetricsCubit(
      loadMetrics: loadMetrics,
      watchRosterChanges: watchRoster,
      watchPaymentChanges: watchPayments,
      clock: () => DateTime(2026, 10, 31),
    );
  });

  tearDown(() async {
    await cubit.close();
    await paymentChanges.close();
  });

  test('opens on the current month and cannot go past it', () async {
    await cubit.load();

    expect(ready().month, october);
    expect(ready().canShowNextMonth, isFalse);

    cubit.showNextMonth();
    expect(ready().month, october);
  });

  test('a new payment reloads without moving off the month shown', () async {
    await cubit.load();
    cubit.showPreviousMonth();

    paymentChanges.add(null);
    await pumpEventQueue();

    verify(() => loadMetrics()).called(2);
    expect(ready().month, september);
  });

  test('tells being offline apart from a server problem', () async {
    when(() => loadMetrics())
        .thenAnswer((_) async => const Left(NetworkFailure()));

    await cubit.load();

    expect(cubit.state, const ClubMetricsFailure(isOffline: true));
  });
}
