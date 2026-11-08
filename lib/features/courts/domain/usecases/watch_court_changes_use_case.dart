import '../repositories/court_repository.dart';

class WatchCourtChangesUseCase {
  final CourtRepository repository;

  WatchCourtChangesUseCase(this.repository);

  Stream<void> call() => repository.courtChanges;
}
