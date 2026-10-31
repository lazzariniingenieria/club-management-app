import '../repositories/admin_repository.dart';

class WatchAdminChangesUseCase {
  final AdminRepository repository;

  WatchAdminChangesUseCase(this.repository);

  Stream<void> call() => repository.adminChanges;
}
