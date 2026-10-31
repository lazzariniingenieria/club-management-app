import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/club.dart';
import '../repositories/club_repository.dart';

class UpdateMonthlyFeeUseCase {
  final ClubRepository repository;

  UpdateMonthlyFeeUseCase(this.repository);

  Future<Either<Failure, Club>> call(int? monthlyFeeCents) {
    if (monthlyFeeCents != null && monthlyFeeCents <= 0) {
      return Future.value(const Left(ValidationFailure('Fee must be > 0')));
    }

    return repository.updateMonthlyFee(monthlyFeeCents);
  }
}
