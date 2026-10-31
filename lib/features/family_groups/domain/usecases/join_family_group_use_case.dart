import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../members/domain/repositories/member_repository.dart';

class JoinFamilyGroupUseCase {
  final MemberRepository repository;

  JoinFamilyGroupUseCase(this.repository);

  Future<Either<Failure, void>> call(int memberId, int familyGroupId) async {
    final joined = await repository.assignFamilyGroup(memberId, familyGroupId);
    final failure = joined.getLeft().toNullable();
    if (failure is! ResponseTimeoutFailure) return joined;

    final landed = await _alreadyIn(memberId, familyGroupId);

    return landed ? const Right(null) : joined;
  }

  Future<bool> _alreadyIn(int memberId, int familyGroupId) async {
    final member = await repository.loadMember(memberId);

    return member.fold(
      (_) => false,
      (member) => member.familyGroupId == familyGroupId,
    );
  }
}
