import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/club/domain/entities/club.dart';
import 'package:club_management_app/features/club/domain/repositories/club_repository.dart';
import 'package:club_management_app/features/club/domain/usecases/load_club_use_case.dart';
import 'package:club_management_app/features/member_accounts/domain/entities/member_account.dart';
import 'package:club_management_app/features/member_accounts/domain/repositories/member_account_repository.dart';
import 'package:club_management_app/features/member_accounts/domain/usecases/create_member_account_use_case.dart';
import 'package:club_management_app/features/member_accounts/domain/usecases/load_member_account_use_case.dart';
import 'package:club_management_app/features/member_accounts/domain/usecases/reset_member_account_password_use_case.dart';
import 'package:club_management_app/features/member_accounts/presentation/cubit/member_account_cubit.dart';
import 'package:club_management_app/features/member_accounts/presentation/cubit/member_account_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockClubRepository extends Mock implements ClubRepository {}

class MockMemberAccountRepository extends Mock
    implements MemberAccountRepository {}

const int memberId = 34;
const String password = 's3cr3t123';
const Club enabledClub = Club(id: 1, name: 'Club 1', memberAppEnabled: true);

const MemberAccount account = MemberAccount(
  id: 40,
  memberId: memberId,
  dni: '30111222',
  role: MemberAccountRole.member,
  isActive: true,
);

void main() {
  late MockClubRepository club;
  late MockMemberAccountRepository accounts;
  late MemberAccountCubit cubit;

  setUp(() {
    club = MockClubRepository();
    accounts = MockMemberAccountRepository();
    when(() => club.loadClub())
        .thenAnswer((_) async => const Right(enabledClub));
    when(() => accounts.loadAccount(memberId))
        .thenAnswer((_) async => const Right(null));
    cubit = MemberAccountCubit(
      loadClub: LoadClubUseCase(club),
      loadAccount: LoadMemberAccountUseCase(accounts),
      createAccount: CreateMemberAccountUseCase(accounts),
      resetPassword: ResetMemberAccountPasswordUseCase(accounts),
    );
  });

  tearDown(() => cubit.close());

  test('a member without an account is ready with no account', () async {
    await cubit.load(memberId);

    expect(cubit.state, const MemberAccountReady(null));
  });

  test('a club with the member app off disables the account', () async {
    when(() => club.loadClub())
        .thenAnswer((_) async => const Right(Club(id: 1, name: 'Club 1')));

    await cubit.load(memberId);

    expect(cubit.state, const MemberAccountDisabled());
    verifyNever(() => accounts.loadAccount(any()));
  });

  test('an unreachable account is reported as offline', () async {
    when(() => accounts.loadAccount(memberId))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    await cubit.load(memberId);

    expect(cubit.state, const MemberAccountFailure(isOffline: true));
  });

  test('a club that fails to load is reported as a server failure', () async {
    when(() => club.loadClub())
        .thenAnswer((_) async => const Left(ServerFailure()));

    await cubit.load(memberId);

    expect(cubit.state, const MemberAccountFailure(isOffline: false));
  });

  test('a created account replaces the missing one', () async {
    when(() => accounts.createAccount(memberId, password))
        .thenAnswer((_) async => const Right(account));
    await cubit.load(memberId);

    final failure = await cubit.createAccount(password);

    expect(failure, isNull);
    expect(cubit.state, const MemberAccountReady(account));
  });

  test('a conflict when creating reloads only once asked to', () async {
    when(() => accounts.createAccount(memberId, password))
        .thenAnswer((_) async => const Left(ConflictFailure()));
    await cubit.load(memberId);

    final failure = await cubit.createAccount(password);
    when(() => accounts.loadAccount(memberId))
        .thenAnswer((_) async => const Right(account));

    expect(failure, isA<ConflictFailure>());
    expect(cubit.state, const MemberAccountReady(null));

    await cubit.reloadIfStale();

    expect(cubit.state, const MemberAccountReady(account));
  });

  test('a reset of an account that is gone leaves the card stale', () async {
    when(() => accounts.resetPassword(memberId, password))
        .thenAnswer((_) async => const Left(NotFoundFailure()));
    await cubit.load(memberId);

    await cubit.resetPassword(password);
    await cubit.reloadIfStale();

    verify(() => accounts.loadAccount(memberId)).called(2);
  });

  test('a lost connection when saving does not reload', () async {
    when(() => accounts.createAccount(memberId, password))
        .thenAnswer((_) async => const Left(NetworkFailure()));
    await cubit.load(memberId);

    await cubit.createAccount(password);
    await cubit.reloadIfStale();

    verify(() => accounts.loadAccount(memberId)).called(1);
  });

  test('a reset keeps showing the account', () async {
    when(() => accounts.loadAccount(memberId))
        .thenAnswer((_) async => const Right(account));
    when(() => accounts.resetPassword(memberId, password))
        .thenAnswer((_) async => const Right(account));
    await cubit.load(memberId);

    final failure = await cubit.resetPassword(password);

    expect(failure, isNull);
    expect(cubit.state, const MemberAccountReady(account));
  });
}
