import '../repositories/court_block_repository.dart';

class WatchCourtBlockChangesUseCase {
  final CourtBlockRepository repository;

  WatchCourtBlockChangesUseCase(this.repository);

  Stream<void> call() => repository.blockChanges;
}
