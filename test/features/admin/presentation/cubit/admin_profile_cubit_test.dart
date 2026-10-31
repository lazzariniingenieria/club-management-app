import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/admin/presentation/cubit/admin_profile_cubit.dart';
import 'package:club_management_app/features/admin/presentation/cubit/admin_profile_state.dart';
import 'package:club_management_app/features/admins/domain/usecases/change_own_password_use_case.dart';
import 'package:club_management_app/features/club/domain/entities/club.dart';
import 'package:club_management_app/features/club/domain/usecases/load_club_use_case.dart';
import 'package:club_management_app/features/club/domain/usecases/update_monthly_fee_use_case.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/members/domain/repositories/member_repository.dart';
import 'package:club_management_app/features/members/domain/usecases/load_member_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLoadClubUseCase extends Mock implements LoadClubUseCase {}

class MockUpdateMonthlyFeeUseCase extends Mock
    implements UpdateMonthlyFeeUseCase {}

class MockChangeOwnPasswordUseCase extends Mock
    implements ChangeOwnPasswordUseCase {}

class MockMemberRepository extends Mock implements MemberRepository {}

void main() {
  late MockLoadClubUseCase loadClub;
  late MockMemberRepository members;
  late MockChangeOwnPasswordUseCase changeOwnPassword;
  late AdminProfileCubit cubit;

  const club = Club(id: 1, name: 'Club 1', monthlyFeeCents: 1500000);
  const linked = Member(
    id: 5,
    firstName: 'Ana',
    lastName: 'Gómez',
    dni: '30111222',
    status: MemberStatus.active,
    daysOverdue: 0,
  );

  setUp(() {
    loadClub = MockLoadClubUseCase();
    members = MockMemberRepository();
    changeOwnPassword = MockChangeOwnPasswordUseCase();
    cubit = AdminProfileCubit(
      loadClub: loadClub,
      loadMember: LoadMemberUseCase(members),
      updateMonthlyFee: MockUpdateMonthlyFeeUseCase(),
      changeOwnPassword: changeOwnPassword,
    );
    when(() => loadClub()).thenAnswer((_) async => const Right(club));
  });

  tearDown(() => cubit.close());

  test('reads only the linked member, never the whole roster', () async {
    when(() => members.loadMember(5))
        .thenAnswer((_) async => const Right(linked));

    await cubit.load(memberId: 5);

    expect(cubit.state.linkedMember, linked);
    verify(() => members.loadMember(5)).called(1);
    verifyNever(() => members.loadMembers());
  });

  test('a failed member read keeps the rest of the profile usable', () async {
    when(() => members.loadMember(5))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    await cubit.load(memberId: 5);

    expect(cubit.state.clubStatus, ProfileClubStatus.ready);
    expect(cubit.state.club, club);
    expect(cubit.state.linkedMember, isNull);
    expect(cubit.state.isLoadingMember, isFalse);
  });

  test('an account without a member reads no member at all', () async {
    await cubit.load();

    verifyNever(() => members.loadMember(any()));
    expect(cubit.state.clubStatus, ProfileClubStatus.ready);
  });

  test('changes the password of the signed-in account', () async {
    when(() => changeOwnPassword('nueva-clave-1'))
        .thenAnswer((_) async => const Right(null));

    expect(await cubit.changePassword('nueva-clave-1'), isNull);
    verify(() => changeOwnPassword('nueva-clave-1')).called(1);
  });

  test('hands a rejected password change back to the sheet', () async {
    when(() => changeOwnPassword(any()))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    expect(await cubit.changePassword('nueva-clave-1'), const NetworkFailure());
  });
}
