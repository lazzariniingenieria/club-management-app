import '../repositories/member_repository.dart';

class WatchRosterChangesUseCase {
  final MemberRepository repository;

  WatchRosterChangesUseCase(this.repository);

  Stream<void> call() => repository.rosterChanges;
}
