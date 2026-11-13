import 'package:equatable/equatable.dart';

class Club extends Equatable {
  final int id;
  final String name;
  final int? monthlyFeeCents;
  final bool courtsEnabled;

  const Club({
    required this.id,
    required this.name,
    this.monthlyFeeCents,
    this.courtsEnabled = false,
  });

  bool get hasMonthlyFee => monthlyFeeCents != null;

  @override
  List<Object?> get props => [id, name, monthlyFeeCents, courtsEnabled];
}
