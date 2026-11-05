import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/domain/repositories/member_repository.dart';
import '../../../payments/domain/entities/payment.dart';
import '../../../payments/domain/repositories/payment_repository.dart';
import '../entities/club_metrics.dart';

class LoadClubMetricsUseCase {
  final PaymentRepository payments;
  final MemberRepository members;

  LoadClubMetricsUseCase({required this.payments, required this.members});

  Future<Either<Failure, ClubMetrics>> call() async {
    final results = await Future.wait<Object>([
      payments.loadPayments(),
      members.loadMembers(),
    ]);
    final collected = results[0] as Either<Failure, List<Payment>>;
    final roster = results[1] as Either<Failure, List<Member>>;

    return collected.flatMap(
      (collected) => roster.map(
        (roster) => ClubMetrics(payments: collected, members: roster),
      ),
    );
  }
}
