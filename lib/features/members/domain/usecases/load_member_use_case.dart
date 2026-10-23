import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/member.dart';
import '../repositories/member_repository.dart';

class LoadMemberUseCase {
  final MemberRepository repository;

  LoadMemberUseCase(this.repository);

  Future<Either<Failure, Member>> call(int memberId) =>
      repository.loadMember(memberId);
}
