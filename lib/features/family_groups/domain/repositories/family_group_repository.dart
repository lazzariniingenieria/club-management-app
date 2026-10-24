import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/family_group.dart';

abstract class FamilyGroupRepository {
  Stream<void> get groupChanges;

  Future<Either<Failure, FamilyGroup>> loadGroup(int familyGroupId);

  Future<Either<Failure, List<FamilyGroup>>> loadGroups();

  Future<Either<Failure, FamilyGroup>> createGroup({String? name});

  Future<Either<Failure, void>> renameGroup(int familyGroupId, String? name);
}
