import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/member_repository.dart';

class SetMemberActiveUseCase {
  final MemberRepository repository;

  SetMemberActiveUseCase(this.repository);

  Future<Either<Failure, void>> call(int memberId, {required bool isActive}) =>
      repository.setMemberActive(memberId, isActive: isActive);
}
