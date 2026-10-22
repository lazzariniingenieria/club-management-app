import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/club.dart';
import '../repositories/club_repository.dart';

class LoadClubUseCase {
  final ClubRepository repository;

  LoadClubUseCase(this.repository);

  Future<Either<Failure, Club>> call() => repository.loadClub();
}
