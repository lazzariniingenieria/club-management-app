import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/member_draft.dart';
import '../repositories/member_repository.dart';

class UpdateMemberUseCase {
  final MemberRepository repository;

  UpdateMemberUseCase(this.repository);

  Future<Either<Failure, void>> call(int memberId, MemberDraft draft) =>
      repository.updateMember(memberId, draft);
}
