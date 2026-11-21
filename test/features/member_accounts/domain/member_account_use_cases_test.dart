import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/member_accounts/domain/entities/member_account.dart';
import 'package:club_management_app/features/member_accounts/domain/repositories/member_account_repository.dart';
import 'package:club_management_app/features/member_accounts/domain/usecases/create_member_account_use_case.dart';
import 'package:club_management_app/features/member_accounts/domain/usecases/load_member_account_use_case.dart';
import 'package:club_management_app/features/member_accounts/domain/usecases/reset_member_account_password_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockMemberAccountRepository extends Mock
    implements MemberAccountRepository {}

const MemberAccount account = MemberAccount(
  id: 40,
  memberId: 34,
  dni: '30111222',
  role: MemberAccountRole.member,
  isActive: true,
);

void main() {
  late MockMemberAccountRepository repository;

  setUp(() => repository = MockMemberAccountRepository());

  test('loading a member without an account gives no account', () async {
    when(() => repository.loadAccount(34))
        .thenAnswer((_) async => const Right(null));

    final result = await LoadMemberAccountUseCase(repository)(34);

    expect(result, const Right<Failure, MemberAccount?>(null));
  });

  test('creates the account with a valid password', () async {
    when(() => repository.createAccount(34, 's3cr3t123'))
        .thenAnswer((_) async => const Right(account));

    final result =
        await CreateMemberAccountUseCase(repository)(34, 's3cr3t123');

    expect(result, const Right<Failure, MemberAccount>(account));
  });

  test('a short initial password never reaches the repository', () async {
    final result = await CreateMemberAccountUseCase(repository)(34, '123');

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repository.createAccount(any(), any()));
  });

  test('resets the password with a valid one', () async {
    when(() => repository.resetPassword(34, 'n3wS3cr3t'))
        .thenAnswer((_) async => const Right(account));

    final result =
        await ResetMemberAccountPasswordUseCase(repository)(34, 'n3wS3cr3t');

    expect(result, const Right<Failure, MemberAccount>(account));
  });

  test('a blank reset password never reaches the repository', () async {
    final result =
        await ResetMemberAccountPasswordUseCase(repository)(34, '         ');

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repository.resetPassword(any(), any()));
  });
}
