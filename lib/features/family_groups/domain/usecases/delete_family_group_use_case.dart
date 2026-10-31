import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../members/domain/repositories/member_repository.dart';
import '../repositories/family_group_repository.dart';

class DeleteFamilyGroupUseCase {
  final FamilyGroupRepository groups;
  final MemberRepository members;

  DeleteFamilyGroupUseCase({required this.groups, required this.members});

  Future<Either<Failure, void>> call(int familyGroupId) async {
    final deleted = await groups.deleteGroup(familyGroupId);
    final failure = deleted.getLeft().toNullable();
    final mayHaveChanged = failure == null || failure is ResponseTimeoutFailure;
    if (mayHaveChanged) members.notifyRosterChanged();

    return deleted;
  }
}
