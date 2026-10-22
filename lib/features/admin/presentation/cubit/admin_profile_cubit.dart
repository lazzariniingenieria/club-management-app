import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../admins/domain/usecases/reset_admin_password_use_case.dart';
import '../../../club/domain/entities/club.dart';
import '../../../club/domain/usecases/load_club_use_case.dart';
import '../../../club/domain/usecases/update_monthly_fee_use_case.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/domain/usecases/load_members_use_case.dart';
import 'admin_profile_state.dart';

class AdminProfileCubit extends Cubit<AdminProfileState> {
  final LoadClubUseCase _loadClub;
  final LoadMembersUseCase _loadMembers;
  final UpdateMonthlyFeeUseCase _updateMonthlyFee;
  final ResetAdminPasswordUseCase _resetPassword;

  AdminProfileCubit({
    required LoadClubUseCase loadClub,
    required LoadMembersUseCase loadMembers,
    required UpdateMonthlyFeeUseCase updateMonthlyFee,
    required ResetAdminPasswordUseCase resetPassword,
  })  : _loadClub = loadClub,
        _loadMembers = loadMembers,
        _updateMonthlyFee = updateMonthlyFee,
        _resetPassword = resetPassword,
        super(const AdminProfileState());

  int? _memberId;

  Future<void> load({int? memberId}) async {
    _memberId = memberId;
    emit(AdminProfileState(isLoadingMember: memberId != null));

    final results = await Future.wait<Object?>([
      _loadClub(),
      if (memberId != null) _loadMembers(),
    ]);
    if (isClosed) return;

    emit(
      AdminProfileState(
        clubStatus: _statusOf(results[0] as Either<Failure, Club>),
        club: (results[0] as Either<Failure, Club>).getRight().toNullable(),
        linkedMember: results.length > 1
            ? _linkedMemberIn(results[1] as Either<Failure, List<Member>>)
            : null,
      ),
    );
  }

  Future<void> reload() => load(memberId: _memberId);

  Future<Failure?> updateMonthlyFee(int? monthlyFeeCents) async {
    final result = await _updateMonthlyFee(monthlyFeeCents);
    if (isClosed) return result.getLeft().toNullable();

    return result.fold<Failure?>((failure) => failure, (club) {
      emit(state.withClub(club));

      return null;
    });
  }

  Future<Failure?> changePassword(int accountId, String newPassword) async {
    final result = await _resetPassword(accountId, newPassword);

    return result.getLeft().toNullable();
  }

  Member? _linkedMemberIn(Either<Failure, List<Member>> roster) {
    final members = roster.getRight().toNullable() ?? const <Member>[];

    for (final member in members) {
      if (member.id == _memberId) return member;
    }

    return null;
  }

  static ProfileClubStatus _statusOf(Either<Failure, Club> club) {
    return club.fold(
      (failure) => failure is NetworkFailure
          ? ProfileClubStatus.offline
          : ProfileClubStatus.failed,
      (_) => ProfileClubStatus.ready,
    );
  }
}
