import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/member_ledger.dart';
import '../repositories/payment_repository.dart';

class LoadMemberLedgerUseCase {
  final PaymentRepository repository;

  LoadMemberLedgerUseCase(this.repository);

  Future<Either<Failure, MemberLedger>> call(int memberId) =>
      repository.loadLedger(memberId);
}
