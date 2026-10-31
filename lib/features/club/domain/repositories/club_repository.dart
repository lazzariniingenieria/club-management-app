import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/club.dart';

abstract class ClubRepository {
  Future<Either<Failure, Club>> loadClub();

  Future<Either<Failure, Club>> updateMonthlyFee(int? monthlyFeeCents);
}
