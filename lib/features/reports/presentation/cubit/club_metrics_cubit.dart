import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../members/domain/usecases/watch_roster_changes_use_case.dart';
import '../../../payments/domain/entities/billing_month.dart';
import '../../../payments/domain/usecases/watch_payment_changes_use_case.dart';
import '../../domain/entities/club_metrics.dart';
import '../../domain/usecases/load_club_metrics_use_case.dart';
import 'club_metrics_state.dart';

class ClubMetricsCubit extends Cubit<ClubMetricsState> {
  final LoadClubMetricsUseCase _loadMetrics;
  final DateTime Function() _clock;
  late final List<StreamSubscription<void>> _changeSubscriptions;

  ClubMetricsCubit({
    required LoadClubMetricsUseCase loadMetrics,
    required WatchRosterChangesUseCase watchRosterChanges,
    required WatchPaymentChangesUseCase watchPaymentChanges,
    DateTime Function() clock = DateTime.now,
  })  : _loadMetrics = loadMetrics,
        _clock = clock,
        super(const ClubMetricsLoading()) {
    _changeSubscriptions = [
      watchRosterChanges().listen((_) => load()),
      watchPaymentChanges().listen((_) => load()),
    ];
  }

  @override
  Future<void> close() async {
    await Future.wait(
      _changeSubscriptions.map((subscription) => subscription.cancel()),
    );

    return super.close();
  }

  Future<void> load() async {
    final shown = state;
    if (shown is! ClubMetricsReady) emit(const ClubMetricsLoading());

    final result = await _loadMetrics();
    if (isClosed) return;

    emit(result.fold(_failureFrom, (metrics) => _readyFrom(metrics, shown)));
  }

  void showPreviousMonth() => _show((month) => month.previous);

  void showNextMonth() => _show((month) => month.next);

  void showMonth(BillingMonth month) => _show((_) => month);

  void _show(BillingMonth Function(BillingMonth shown) pick) {
    final current = state;
    if (current is! ClubMetricsReady) return;

    final month = pick(current.month);
    if (current.currentMonth.isBefore(month)) return;

    emit(current.showing(month));
  }

  ClubMetricsState _readyFrom(ClubMetrics metrics, ClubMetricsState shown) {
    final currentMonth = BillingMonth.of(_clock());

    return ClubMetricsReady(
      metrics: metrics,
      month: shown is ClubMetricsReady ? shown.month : currentMonth,
      currentMonth: currentMonth,
    );
  }

  static ClubMetricsState _failureFrom(Failure failure) =>
      ClubMetricsFailure(isOffline: failure is NetworkFailure);
}
