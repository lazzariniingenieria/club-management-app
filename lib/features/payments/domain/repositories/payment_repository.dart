import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/member_ledger.dart';
import '../entities/payment.dart';
import '../entities/payment_draft.dart';
import '../entities/payment_precheck.dart';

abstract class PaymentRepository {
  Stream<void> get paymentChanges;

  Future<Either<Failure, MemberLedger>> loadLedger(int memberId);

  Future<Either<Failure, PaymentPrecheck>> loadPrecheck(int memberId);

  Future<Either<Failure, List<Payment>>> loadPayments();

  Future<Either<Failure, void>> recordPayment(PaymentDraft draft);

  Future<Either<Failure, void>> recordPayments(List<PaymentDraft> drafts);

  Future<Either<Failure, void>> voidPayment(int paymentId, {String? reason});
}
