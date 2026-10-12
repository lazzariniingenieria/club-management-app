import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/member_draft.dart';
import '../repositories/member_repository.dart';

class CreateMemberUseCase {
  final MemberRepository repository;

  CreateMemberUseCase(this.repository);

  Future<Either<Failure, void>> call(MemberDraft draft) =>
      repository.createMember(draft);
}
