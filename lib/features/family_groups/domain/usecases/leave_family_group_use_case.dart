import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../members/domain/repositories/member_repository.dart';

class LeaveFamilyGroupUseCase {
  final MemberRepository repository;

  LeaveFamilyGroupUseCase(this.repository);

  Future<Either<Failure, void>> call(int memberId) =>
      repository.removeFromFamilyGroup(memberId);
}
