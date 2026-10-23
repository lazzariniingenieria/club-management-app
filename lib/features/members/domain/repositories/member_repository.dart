import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/member.dart';
import '../entities/member_draft.dart';

abstract class MemberRepository {
  Stream<void> get rosterChanges;

  Future<Either<Failure, List<Member>>> loadMembers();

  Future<Either<Failure, Member>> loadMember(int memberId);

  Future<Either<Failure, void>> createMember(MemberDraft draft);

  Future<Either<Failure, void>> updateMember(int memberId, MemberDraft draft);

  Future<Either<Failure, void>> setMemberActive(
    int memberId, {
    required bool isActive,
  });

  Future<Either<Failure, void>> assignFamilyGroup(
    int memberId,
    int familyGroupId,
  );

  Future<Either<Failure, void>> removeFromFamilyGroup(int memberId);
}
