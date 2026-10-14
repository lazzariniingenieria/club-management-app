import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/member_ledger.dart';
import '../entities/payment_draft.dart';

abstract class PaymentRepository {
  Stream<void> get paymentChanges;

  Future<Either<Failure, MemberLedger>> loadLedger(int memberId);

  Future<Either<Failure, void>> recordPayment(PaymentDraft draft);

  Future<Either<Failure, void>> voidPayment(int paymentId, {String? reason});
}
