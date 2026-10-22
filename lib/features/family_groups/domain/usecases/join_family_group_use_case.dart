import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../members/domain/repositories/member_repository.dart';

class JoinFamilyGroupUseCase {
  final MemberRepository repository;

  JoinFamilyGroupUseCase(this.repository);

  Future<Either<Failure, void>> call(int memberId, int familyGroupId) =>
      repository.assignFamilyGroup(memberId, familyGroupId);
}
