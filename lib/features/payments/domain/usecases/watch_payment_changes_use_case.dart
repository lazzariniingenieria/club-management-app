import '../repositories/payment_repository.dart';

class WatchPaymentChangesUseCase {
  final PaymentRepository repository;

  WatchPaymentChangesUseCase(this.repository);

  Stream<void> call() => repository.paymentChanges;
}
