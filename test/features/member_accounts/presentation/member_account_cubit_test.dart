import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/admins/domain/repositories/admin_repository.dart';
import 'package:club_management_app/features/club/domain/entities/club.dart';
import 'package:club_management_app/features/club/domain/repositories/club_repository.dart';
import 'package:club_management_app/features/club/domain/usecases/load_club_use_case.dart';
import 'package:club_management_app/features/member_accounts/domain/entities/member_account.dart';
import 'package:club_management_app/features/member_accounts/domain/repositories/member_account_repository.dart';
import 'package:club_management_app/features/member_accounts/domain/usecases/create_member_account_use_case.dart';
import 'package:club_management_app/features/member_accounts/domain/usecases/load_member_account_use_case.dart';
import 'package:club_management_app/features/member_accounts/domain/usecases/promote_member_to_admin_use_case.dart';
import 'package:club_management_app/features/member_accounts/domain/usecases/reset_member_account_password_use_case.dart';
import 'package:club_management_app/features/member_accounts/presentation/cubit/member_account_cubit.dart';
import 'package:club_management_app/features/member_accounts/presentation/cubit/member_account_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockClubRepository extends Mock implements ClubRepository {}

class MockAdminRepository extends Mock implements AdminRepository {}

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
  late MockAdminRepository admins;
  late MemberAccountCubit cubit;

  setUp(() {
    club = MockClubRepository();
    accounts = MockMemberAccountRepository();
    admins = MockAdminRepository();
    when(() => club.loadClub())
        .thenAnswer((_) async => const Right(enabledClub));
    when(() => accounts.loadAccount(memberId))
        .thenAnswer((_) async => const Right(null));
    cubit = MemberAccountCubit(
      loadClub: LoadClubUseCase(club),
      loadAccount: LoadMemberAccountUseCase(accounts),
      createAccount: CreateMemberAccountUseCase(accounts),
      resetPassword: ResetMemberAccountPasswordUseCase(accounts),
      promoteToAdmin: PromoteMemberToAdminUseCase(
        admins: admins,
        accounts: accounts,
      ),
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

  group('promoteToAdmin', () {
    const adminAccount = MemberAccount(
      id: 40,
      memberId: memberId,
      dni: '30111222',
      role: MemberAccountRole.admin,
      isActive: true,
    );

    setUp(() {
      when(() => accounts.loadAccount(memberId))
          .thenAnswer((_) async => const Right(account));
    });

    test('shows the admin account once promoted', () async {
      when(() => admins.promoteMember(memberId)).thenAnswer((_) async {
        when(() => accounts.loadAccount(memberId))
            .thenAnswer((_) async => const Right(adminAccount));
        return const Right(null);
      });
      await cubit.load(memberId);

      final failure = await cubit.promoteToAdmin();

      expect(failure, isNull);
      expect(cubit.state, const MemberAccountReady(adminAccount));
    });

    test('is saving while the promotion is on its way', () async {
      when(() => admins.promoteMember(memberId))
          .thenAnswer((_) async => const Left(ServerFailure()));
      await cubit.load(memberId);

      final states = <Object>[];
      final subscription = cubit.stream.listen(states.add);
      await cubit.promoteToAdmin();
      await pumpEventQueue();
      await subscription.cancel();

      expect(states, const [
        MemberAccountReady(account, isSaving: true),
        MemberAccountReady(account),
      ]);
    });

    test('an account that is gone leaves the card stale', () async {
      when(() => admins.promoteMember(memberId))
          .thenAnswer((_) async => const Left(NotFoundFailure()));
      await cubit.load(memberId);

      final failure = await cubit.promoteToAdmin();
      await cubit.reloadIfStale();

      expect(failure, isA<NotFoundFailure>());
      verify(() => accounts.loadAccount(memberId)).called(2);
    });
  });
}
