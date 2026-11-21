import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../club/domain/entities/club.dart';
import '../../../club/domain/usecases/load_club_use_case.dart';
import '../../domain/entities/member_account.dart';
import '../../domain/usecases/create_member_account_use_case.dart';
import '../../domain/usecases/load_member_account_use_case.dart';
import '../../domain/usecases/reset_member_account_password_use_case.dart';
import 'member_account_state.dart';

class MemberAccountCubit extends Cubit<MemberAccountState> {
  final LoadClubUseCase _loadClub;
  final LoadMemberAccountUseCase _loadAccount;
  final CreateMemberAccountUseCase _createAccount;
  final ResetMemberAccountPasswordUseCase _resetPassword;

  MemberAccountCubit({
    required LoadClubUseCase loadClub,
    required LoadMemberAccountUseCase loadAccount,
    required CreateMemberAccountUseCase createAccount,
    required ResetMemberAccountPasswordUseCase resetPassword,
  })  : _loadClub = loadClub,
        _loadAccount = loadAccount,
        _createAccount = createAccount,
        _resetPassword = resetPassword,
        super(const MemberAccountLoading());

  int? _memberId;
  bool _isStale = false;

  Future<void> load(int memberId) {
    _memberId = memberId;

    return reload();
  }

  Future<void> reload() async {
    final memberId = _memberId;
    if (memberId == null) return;

    _isStale = false;
    emit(const MemberAccountLoading());
    final club = await _loadClub();
    if (isClosed) return;

    await club.fold<Future<void>>(
      (failure) async => emit(_failureState(failure)),
      (club) => _loadAccountOf(memberId, club),
    );
  }

  Future<void> reloadIfStale() async {
    if (_isStale) await reload();
  }

  Future<Failure?> createAccount(String password) {
    return _save((memberId) => _createAccount(memberId, password));
  }

  Future<Failure?> resetPassword(String newPassword) {
    return _save((memberId) => _resetPassword(memberId, newPassword));
  }

  Future<void> _loadAccountOf(int memberId, Club club) async {
    if (!club.memberAppEnabled) {
      emit(const MemberAccountDisabled());
      return;
    }

    final account = await _loadAccount(memberId);
    if (isClosed) return;

    emit(account.fold(_failureState, MemberAccountReady.new));
  }

  Future<Failure?> _save(
    Future<Either<Failure, MemberAccount>> Function(int memberId) save,
  ) async {
    final memberId = _memberId;
    if (memberId == null) return const ValidationFailure('No member loaded');

    final result = await save(memberId);
    if (isClosed) return null;

    return result.fold(_rememberStaleness, (account) {
      emit(MemberAccountReady(account));

      return null;
    });
  }

  Failure _rememberStaleness(Failure failure) {
    if (_leavesAccountStale(failure)) _isStale = true;

    return failure;
  }

  static bool _leavesAccountStale(Failure failure) =>
      failure is ConflictFailure ||
      failure is NotFoundFailure ||
      failure is ValidationFailure;

  static MemberAccountFailure _failureState(Failure failure) =>
      MemberAccountFailure(isOffline: failure is NetworkFailure);
}
