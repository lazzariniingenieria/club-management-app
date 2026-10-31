import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/domain/repositories/member_repository.dart';
import '../entities/family_group.dart';
import '../entities/family_group_detail.dart';
import '../repositories/family_group_repository.dart';

class LoadFamilyGroupDetailUseCase {
  final FamilyGroupRepository groups;
  final MemberRepository members;

  LoadFamilyGroupDetailUseCase({required this.groups, required this.members});

  Future<Either<Failure, FamilyGroupDetail>> call(int familyGroupId) async {
    final results = await Future.wait<Object>([
      groups.loadGroup(familyGroupId),
      members.loadMembers(),
    ]);
    final group = results[0] as Either<Failure, FamilyGroup>;
    final roster = results[1] as Either<Failure, List<Member>>;

    return group.flatMap(
      (group) => roster.map(
        (roster) => FamilyGroupDetail.fromRoster(group, roster),
      ),
    );
  }
}
