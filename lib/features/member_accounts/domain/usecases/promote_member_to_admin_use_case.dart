import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../admins/domain/repositories/admin_repository.dart';
import '../entities/member_account.dart';
import '../repositories/member_account_repository.dart';

class PromoteMemberToAdminUseCase {
  final AdminRepository admins;
  final MemberAccountRepository accounts;

  PromoteMemberToAdminUseCase({required this.admins, required this.accounts});

  Future<Either<Failure, void>> call(int memberId) async {
    final promoted = await admins.promoteMember(memberId);
    if (promoted.getLeft().toNullable() is! ResponseTimeoutFailure) {
      return promoted;
    }

    return await _isAdmin(memberId) ? const Right(null) : promoted;
  }

  Future<bool> _isAdmin(int memberId) async {
    final account = await accounts.loadAccount(memberId);

    return account.fold(
      (_) => false,
      (account) => account?.role == MemberAccountRole.admin,
    );
  }
}
