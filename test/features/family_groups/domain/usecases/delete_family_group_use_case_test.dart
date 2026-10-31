import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/family_groups/domain/repositories/family_group_repository.dart';
import 'package:club_management_app/features/family_groups/domain/usecases/delete_family_group_use_case.dart';
import 'package:club_management_app/features/members/domain/repositories/member_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockFamilyGroupRepository extends Mock implements FamilyGroupRepository {}

class MockMemberRepository extends Mock implements MemberRepository {}

void main() {
  late MockFamilyGroupRepository groups;
  late MockMemberRepository members;
  late DeleteFamilyGroupUseCase deleteGroup;

  void stubDeletion(Either<Failure, void> result) {
    when(() => groups.deleteGroup(7)).thenAnswer((_) async => result);
  }

  setUp(() {
    groups = MockFamilyGroupRepository();
    members = MockMemberRepository();
    deleteGroup = DeleteFamilyGroupUseCase(groups: groups, members: members);
  });

  group('tells the roster that its members lost their group', () {
    test('when the group was deleted', () async {
      stubDeletion(const Right(null));

      final result = await deleteGroup(7);

      expect(result.isRight(), isTrue);
      verify(() => members.notifyRosterChanged()).called(1);
    });

    test('when nobody answered, because the deletion may have landed',
        () async {
      stubDeletion(const Left(ResponseTimeoutFailure()));

      final result = await deleteGroup(7);

      expect(result.getLeft().toNullable(), const ResponseTimeoutFailure());
      verify(() => members.notifyRosterChanged()).called(1);
    });

    test('when the group was already gone, because somebody else deleted it',
        () async {
      stubDeletion(const Left(NotFoundFailure()));

      final result = await deleteGroup(7);

      expect(result.getLeft().toNullable(), const NotFoundFailure());
      verify(() => members.notifyRosterChanged()).called(1);
    });
  });

  group('says nothing when the deletion did not happen', () {
    test('because the connection dropped', () async {
      stubDeletion(const Left(NetworkFailure()));

      final result = await deleteGroup(7);

      expect(result.getLeft().toNullable(), const NetworkFailure());
      verifyNever(() => members.notifyRosterChanged());
    });

    test('because the server failed', () async {
      stubDeletion(const Left(ServerFailure()));

      final result = await deleteGroup(7);

      expect(result.getLeft().toNullable(), const ServerFailure());
      verifyNever(() => members.notifyRosterChanged());
    });
  });
}
