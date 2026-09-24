import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/admin_summary.dart';

abstract class AdminSummaryRepository {
  Future<Either<Failure, AdminSummary>> loadSummary();
}
