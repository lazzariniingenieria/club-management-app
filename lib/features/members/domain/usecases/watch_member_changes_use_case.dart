import '../repositories/member_repository.dart';

class WatchMemberChangesUseCase {
  final MemberRepository repository;

  WatchMemberChangesUseCase(this.repository);

  Stream<void> call() => repository.rosterChanges;
}
