import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/family_group_repository.dart';

class RenameFamilyGroupUseCase {
  final FamilyGroupRepository repository;

  RenameFamilyGroupUseCase(this.repository);

  Future<Either<Failure, void>> call(int familyGroupId, String name) {
    final trimmed = name.trim();

    return repository.renameGroup(
      familyGroupId,
      trimmed.isEmpty ? null : trimmed,
    );
  }
}
