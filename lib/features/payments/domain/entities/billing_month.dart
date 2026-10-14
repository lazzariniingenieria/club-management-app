import 'package:equatable/equatable.dart';

class BillingMonth extends Equatable implements Comparable<BillingMonth> {
  final int year;
  final int month;

  const BillingMonth(this.year, this.month)
      : assert(month >= DateTime.january && month <= DateTime.december);

  factory BillingMonth.of(DateTime day) => BillingMonth(day.year, day.month);

  factory BillingMonth.parse(String isoDay) =>
      BillingMonth.of(DateTime.parse(isoDay));

  BillingMonth get next => month == DateTime.december
      ? BillingMonth(year + 1, DateTime.january)
      : BillingMonth(year, month + 1);

  BillingMonth get previous => month == DateTime.january
      ? BillingMonth(year - 1, DateTime.december)
      : BillingMonth(year, month - 1);

  DateTime get firstDay => DateTime(year, month);

  bool isBefore(BillingMonth other) => compareTo(other) < 0;

  bool isRightBefore(BillingMonth other) => next == other;

  String toIsoDay() {
    final paddedMonth = month.toString().padLeft(2, '0');

    return '$year-$paddedMonth-01';
  }

  static List<BillingMonth> sorted(Iterable<BillingMonth> months) =>
      [...months]..sort();

  int get _ordinal => year * DateTime.monthsPerYear + month;

  @override
  int compareTo(BillingMonth other) => _ordinal.compareTo(other._ordinal);

  @override
  List<Object?> get props => [year, month];
}
