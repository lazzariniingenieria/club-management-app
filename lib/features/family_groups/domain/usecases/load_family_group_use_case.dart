import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/family_group.dart';
import '../repositories/family_group_repository.dart';

class LoadFamilyGroupUseCase {
  final FamilyGroupRepository repository;

  LoadFamilyGroupUseCase(this.repository);

  Future<Either<Failure, FamilyGroup>> call(int familyGroupId) =>
      repository.loadGroup(familyGroupId);
}
