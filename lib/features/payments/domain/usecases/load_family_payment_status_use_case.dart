import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/payment_precheck.dart';
import '../repositories/payment_repository.dart';

class LoadFamilyPaymentStatusUseCase {
  final PaymentRepository repository;

  LoadFamilyPaymentStatusUseCase(this.repository);

  Future<Either<Failure, Map<int, PaymentPrecheck>>> call(
    List<int> memberIds,
  ) async {
    final prechecks = await Future.wait(memberIds.map(repository.loadPrecheck));
    final statuses = <int, PaymentPrecheck>{};
    for (var index = 0; index < memberIds.length; index++) {
      switch (prechecks[index]) {
        case Left(:final value):
          return Left(value);
        case Right(:final value):
          statuses[memberIds[index]] = value;
      }
    }

    return Right(statuses);
  }
}
