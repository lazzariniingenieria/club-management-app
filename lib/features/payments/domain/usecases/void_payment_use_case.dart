import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/payment_repository.dart';

class VoidPaymentUseCase {
  final PaymentRepository repository;

  VoidPaymentUseCase(this.repository);

  Future<Either<Failure, void>> call(int paymentId, {String? reason}) {
    final trimmed = reason?.trim();

    return repository.voidPayment(
      paymentId,
      reason: trimmed == null || trimmed.isEmpty ? null : trimmed,
    );
  }
}
