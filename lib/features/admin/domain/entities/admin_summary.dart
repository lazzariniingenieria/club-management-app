import 'package:equatable/equatable.dart';

class AdminSummary extends Equatable {
  final int activeMembers;
  final int overdueMembers;

  const AdminSummary({
    required this.activeMembers,
    required this.overdueMembers,
  });

  @override
  List<Object?> get props => [activeMembers, overdueMembers];
}
