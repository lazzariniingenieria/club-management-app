import 'package:equatable/equatable.dart';

class Club extends Equatable {
  final int id;
  final String name;
  final int? monthlyFeeCents;

  const Club({required this.id, required this.name, this.monthlyFeeCents});

  bool get hasMonthlyFee => monthlyFeeCents != null;

  @override
  List<Object?> get props => [id, name, monthlyFeeCents];
}
