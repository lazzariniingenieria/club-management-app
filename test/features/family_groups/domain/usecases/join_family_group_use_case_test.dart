import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/family_groups/domain/usecases/join_family_group_use_case.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/members/domain/repositories/member_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockMemberRepository extends Mock implements MemberRepository {}

Member memberIn(int? familyGroupId) => Member(
      id: 4,
      firstName: 'Lucía',
      lastName: 'Álvarez',
      dni: '30111222',
      status: MemberStatus.active,
      daysOverdue: 0,
      familyGroupId: familyGroupId,
    );

void main() {
  late MockMemberRepository members;
  late JoinFamilyGroupUseCase join;

  setUp(() {
    members = MockMemberRepository();
    join = JoinFamilyGroupUseCase(members);
  });

  void assignmentAnswers(Either<Failure, void> result) {
    when(() => members.assignFamilyGroup(4, 7)).thenAnswer((_) async => result);
  }

  test('a confirmed assignment does not read the member again', () async {
    assignmentAnswers(const Right(null));

    final result = await join(4, 7);

    expect(result.isRight(), isTrue);
    verifyNever(() => members.loadMember(any()));
  });

  test('a timeout that already landed in the group counts as done', () async {
    assignmentAnswers(const Left(ResponseTimeoutFailure()));
    when(() => members.loadMember(4))
        .thenAnswer((_) async => Right(memberIn(7)));

    final result = await join(4, 7);

    expect(result.isRight(), isTrue);
  });

  test('a timeout that did not land keeps the failure', () async {
    assignmentAnswers(const Left(ResponseTimeoutFailure()));
    when(() => members.loadMember(4))
        .thenAnswer((_) async => Right(memberIn(null)));

    final result = await join(4, 7);

    expect(result, const Left<Failure, void>(ResponseTimeoutFailure()));
  });

  test('a timeout whose check also fails keeps the failure', () async {
    assignmentAnswers(const Left(ResponseTimeoutFailure()));
    when(() => members.loadMember(4))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await join(4, 7);

    expect(result.isLeft(), isTrue);
  });

  test('a server error is reported without reading the member', () async {
    assignmentAnswers(const Left(ServerFailure()));

    final result = await join(4, 7);

    expect(result, const Left<Failure, void>(ServerFailure()));
    verifyNever(() => members.loadMember(any()));
  });
}
