import '../repositories/family_group_repository.dart';

class WatchFamilyGroupChangesUseCase {
  final FamilyGroupRepository repository;

  WatchFamilyGroupChangesUseCase(this.repository);

  Stream<void> call() => repository.groupChanges;
}
