import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../club/domain/entities/club.dart';
import '../../../club/domain/repositories/club_repository.dart';
import '../entities/member_ledger.dart';
import '../repositories/payment_repository.dart';

class LoadMemberLedgerUseCase {
  final PaymentRepository payments;
  final ClubRepository club;

  LoadMemberLedgerUseCase({required this.payments, required this.club});

  Future<Either<Failure, MemberLedger>> call(int memberId) async {
    final results = await Future.wait<Object>([
      payments.loadLedger(memberId),
      club.loadClub(),
    ]);
    final ledger = results[0] as Either<Failure, MemberLedger>;
    final monthlyFee = _monthlyFeeOf(results[1] as Either<Failure, Club>);

    return ledger.map((ledger) => ledger.withMonthlyFee(monthlyFee));
  }

  static int? _monthlyFeeOf(Either<Failure, Club> club) =>
      club.getRight().toNullable()?.monthlyFeeCents;
}
