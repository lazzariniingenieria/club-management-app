import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/features/members/data/datasources/member_fake_data_source.dart';
import 'package:club_management_app/features/members/data/repositories/member_repository_impl.dart';
import 'package:club_management_app/features/members/domain/entities/member_draft.dart';
import 'package:flutter_test/flutter_test.dart';

class SilentLogger implements AppLogger {
  const SilentLogger();

  @override
  void info(String message, {String? context}) {}

  @override
  void warning(String message, {String? context}) {}

  @override
  void error(String message,
      {String? context, Object? cause, StackTrace? stackTrace}) {}
}

void main() {
  late MemberRepositoryImpl repository;
  late List<void> announcements;

  const newMember = MemberDraft(
    firstName: 'Ana',
    lastName: 'Nueva',
    dni: '99999999',
  );
  final seeded = MemberFakeDataSource.roster.first;

  setUp(() {
    repository = MemberRepositoryImpl(
      remoteDataSource: MemberFakeDataSource(latency: Duration.zero),
      logger: const SilentLogger(),
    );
    announcements = [];
    repository.rosterChanges.listen(announcements.add);
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('the roster announces every write that went through', () {
    test('a created member', () async {
      await repository.createMember(newMember);
      await settle();

      expect(announcements, hasLength(1));
    });

    test('an edited member', () async {
      await repository.updateMember(seeded.id, MemberDraft.fromMember(seeded));
      await settle();

      expect(announcements, hasLength(1));
    });

    test('a member deactivated and reactivated', () async {
      await repository.setMemberActive(seeded.id, isActive: false);
      await repository.setMemberActive(seeded.id, isActive: true);
      await settle();

      expect(announcements, hasLength(2));
    });
  });

  test('a rejected write announces nothing, the roster did not change',
      () async {
    final duplicated = MemberDraft(
      firstName: 'Ana',
      lastName: 'Nueva',
      dni: seeded.dni,
    );

    final result = await repository.createMember(duplicated);
    await settle();

    expect(result.isLeft(), isTrue);
    expect(announcements, isEmpty);
  });

  test('reading the roster announces nothing', () async {
    await repository.loadMembers();
    await settle();

    expect(announcements, isEmpty);
  });
}
