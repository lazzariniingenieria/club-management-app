import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/features/member_accounts/data/datasources/member_account_remote_data_source.dart';
import 'package:club_management_app/features/member_accounts/data/models/member_account_model.dart';
import 'package:club_management_app/features/member_accounts/data/repositories/member_account_repository_impl.dart';
import 'package:club_management_app/features/member_accounts/domain/entities/member_account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

const MemberAccountModel storedAccount = MemberAccountModel(
  id: 40,
  memberId: 34,
  dni: '30111222',
  role: MemberAccountRole.member,
  isActive: true,
);

class ScriptedAccountSource implements MemberAccountRemoteDataSource {
  ScriptedAccountSource({this.account = storedAccount, this.error});

  final MemberAccountModel? account;
  final Exception? error;

  Future<T> _answer<T>(T value) async {
    final failure = error;
    if (failure != null) throw failure;

    return value;
  }

  @override
  Future<MemberAccountModel?> fetchAccount(int memberId) => _answer(account);

  @override
  Future<MemberAccountModel> createAccount(int memberId, String password) =>
      _answer(storedAccount);

  @override
  Future<MemberAccountModel> resetPassword(int memberId, String newPassword) =>
      _answer(storedAccount);
}

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
  MemberAccountRepositoryImpl repositoryOver(ScriptedAccountSource source) {
    return MemberAccountRepositoryImpl(
      remoteDataSource: source,
      logger: const SilentLogger(),
    );
  }

  Failure? failureOf<T>(Either<Failure, T> result) =>
      result.getLeft().toNullable();

  test('loads the account of the member', () async {
    final result =
        await repositoryOver(ScriptedAccountSource()).loadAccount(34);

    expect(result.getRight().toNullable(), storedAccount);
  });

  test('a member without an account loads as no account', () async {
    final result = await repositoryOver(ScriptedAccountSource(account: null))
        .loadAccount(34);

    expect(result.isRight(), isTrue);
    expect(result.getRight().toNullable(), isNull);
  });

  test('a conflict when creating maps to a conflict failure', () async {
    final repository =
        repositoryOver(ScriptedAccountSource(error: ConflictException()));

    expect(
      failureOf(await repository.createAccount(34, 's3cr3t123')),
      isA<ConflictFailure>(),
    );
  });

  test('a rejected creation maps to a validation failure', () async {
    final repository =
        repositoryOver(ScriptedAccountSource(error: ValidationException()));

    expect(
      failureOf(await repository.createAccount(34, 's3cr3t123')),
      isA<ValidationFailure>(),
    );
  });

  test('a reset without a member account maps to not found', () async {
    final repository =
        repositoryOver(ScriptedAccountSource(error: NotFoundException()));

    expect(
      failureOf(await repository.resetPassword(34, 'n3wS3cr3t')),
      isA<NotFoundFailure>(),
    );
  });

  test('a lost connection maps to a network failure', () async {
    final repository =
        repositoryOver(ScriptedAccountSource(error: NetworkException()));

    expect(failureOf(await repository.loadAccount(34)), isA<NetworkFailure>());
  });

  test('a server error maps to a server failure', () async {
    final repository =
        repositoryOver(ScriptedAccountSource(error: ServerException()));

    expect(failureOf(await repository.loadAccount(34)), isA<ServerFailure>());
  });
}
