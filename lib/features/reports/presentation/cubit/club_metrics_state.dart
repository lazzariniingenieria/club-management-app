import 'package:equatable/equatable.dart';

import '../../../payments/domain/entities/billing_month.dart';
import '../../domain/entities/club_metrics.dart';

sealed class ClubMetricsState extends Equatable {
  const ClubMetricsState();

  @override
  List<Object?> get props => [];
}

class ClubMetricsLoading extends ClubMetricsState {
  const ClubMetricsLoading();
}

class ClubMetricsReady extends ClubMetricsState {
  static const int chartMonths = 6;

  final ClubMetrics metrics;
  final BillingMonth month;
  final BillingMonth currentMonth;

  const ClubMetricsReady({
    required this.metrics,
    required this.month,
    required this.currentMonth,
  });

  bool get canShowNextMonth => month.isBefore(currentMonth);

  MonthlyCollection get collection => metrics.collectionIn(month);

  MonthlyCollection get previousCollection =>
      metrics.collectionIn(month.previous);

  int get newMembers => metrics.newMembersIn(month);

  List<MonthlyCollection> get recentCollections =>
      metrics.collectionsEndingIn(month, chartMonths);

  ClubMetricsReady showing(BillingMonth month) => ClubMetricsReady(
        metrics: metrics,
        month: month,
        currentMonth: currentMonth,
      );

  @override
  List<Object?> get props => [metrics, month, currentMonth];
}

class ClubMetricsFailure extends ClubMetricsState {
  final bool isOffline;

  const ClubMetricsFailure({required this.isOffline});

  @override
  List<Object?> get props => [isOffline];
}
