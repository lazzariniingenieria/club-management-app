import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/domain/repositories/member_repository.dart';
import '../entities/family_group.dart';
import '../entities/family_group_candidates.dart';
import '../repositories/family_group_repository.dart';

class LoadFamilyGroupCandidatesUseCase {
  final FamilyGroupRepository groups;
  final MemberRepository members;

  LoadFamilyGroupCandidatesUseCase({
    required this.groups,
    required this.members,
  });

  Future<Either<Failure, FamilyGroupCandidates>> call() async {
    final results = await Future.wait<Object>([
      members.loadMembers(),
      groups.loadGroups(),
    ]);
    final roster = results[0] as Either<Failure, List<Member>>;
    final allGroups = results[1] as Either<Failure, List<FamilyGroup>>;

    return roster.flatMap(
      (roster) => allGroups.map(
        (allGroups) => FamilyGroupCandidates(roster: roster, groups: allGroups),
      ),
    );
  }
}
