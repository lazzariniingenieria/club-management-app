import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/court.dart';
import '../repositories/court_repository.dart';

class LoadCourtsUseCase {
  final CourtRepository repository;

  LoadCourtsUseCase(this.repository);

  Future<Either<Failure, List<Court>>> call() async {
    final result = await repository.loadCourts();

    return result.map(_sorted);
  }

  static List<Court> _sorted(List<Court> courts) =>
      [...courts]..sort(_compare);

  static int _compare(Court a, Court b) {
    if (a.isActive != b.isActive) return a.isActive ? -1 : 1;

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}
