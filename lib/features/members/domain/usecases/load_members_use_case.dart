import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/member.dart';
import '../repositories/member_repository.dart';

class LoadMembersUseCase {
  final MemberRepository repository;

  LoadMembersUseCase(this.repository);

  Future<Either<Failure, List<Member>>> call() => repository.loadMembers();
}
