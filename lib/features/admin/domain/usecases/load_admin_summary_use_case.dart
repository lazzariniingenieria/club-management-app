import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/admin_summary.dart';
import '../repositories/admin_summary_repository.dart';

class LoadAdminSummaryUseCase {
  final AdminSummaryRepository repository;

  LoadAdminSummaryUseCase(this.repository);

  Future<Either<Failure, AdminSummary>> call() => repository.loadSummary();
}
