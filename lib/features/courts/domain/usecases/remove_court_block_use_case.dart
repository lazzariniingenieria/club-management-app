import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/court_block_repository.dart';

class RemoveCourtBlockUseCase {
  final CourtBlockRepository repository;

  RemoveCourtBlockUseCase(this.repository);

  Future<Either<Failure, void>> call(int courtId, int blockId) async {
    final result = await repository.removeBlock(courtId, blockId);
    final alreadyRemoved = result.getLeft().toNullable() is NotFoundFailure;

    return alreadyRemoved ? const Right(null) : result;
  }
}
