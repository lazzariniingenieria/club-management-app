import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../members/domain/usecases/watch_member_changes_use_case.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/load_member_ledger_use_case.dart';
import '../../domain/usecases/void_payment_use_case.dart';
import 'member_ledger_state.dart';

class MemberLedgerCubit extends Cubit<MemberLedgerState> {
  final LoadMemberLedgerUseCase _loadLedger;
  final VoidPaymentUseCase _voidPayment;
  late final StreamSubscription<void> _memberChangesSubscription;

  MemberLedgerCubit({
    required LoadMemberLedgerUseCase loadLedger,
    required VoidPaymentUseCase voidPayment,
    required WatchMemberChangesUseCase watchMemberChanges,
  })  : _loadLedger = loadLedger,
        _voidPayment = voidPayment,
        super(const MemberLedgerLoading()) {
    _memberChangesSubscription =
        watchMemberChanges().listen((_) => _reloadChangedMember());
  }

  int? _memberId;
  bool _isLoading = false;
  bool _memberChangedWhileLoading = false;

  @override
  Future<void> close() async {
    await _memberChangesSubscription.cancel();

    return super.close();
  }

  Future<void> load(int memberId) async {
    _memberId = memberId;
    _isLoading = true;
    if (state is! MemberLedgerReady) emit(const MemberLedgerLoading());

    final result = await _loadLedger(memberId);
    _isLoading = false;
    if (isClosed) return;

    emit(result.fold(_stateFor, MemberLedgerReady.new));
    if (_memberChangedWhileLoading) await _reloadChangedMember();
  }

  Future<void> reload() async {
    final memberId = _memberId;
    if (memberId != null) await load(memberId);
  }

  Future<Failure?> voidPayment(Payment payment, {String? reason}) async {
    final result = await _voidPayment(payment.id, reason: reason);
    final failure = result.fold<Failure?>((failure) => failure, (_) => null);

    if (!_leftLedgerUntouched(failure)) await reload();
    if (failure is ResponseTimeoutFailure && _wasVoided(payment)) return null;

    return failure;
  }

  Future<void> _reloadChangedMember() async {
    _memberChangedWhileLoading = _isLoading;
    if (_isLoading) return;

    await reload();
  }

  bool _wasVoided(Payment payment) {
    final current = state;
    if (current is! MemberLedgerReady) return false;

    return current.ledger.payments
        .any((each) => each.id == payment.id && each.isVoided);
  }

  static bool _leftLedgerUntouched(Failure? failure) {
    return failure != null &&
        failure is! ConflictFailure &&
        failure is! ResponseTimeoutFailure;
  }

  static MemberLedgerState _stateFor(Failure failure) {
    return switch (failure) {
      NotFoundFailure() => const MemberLedgerMissing(),
      NetworkFailure() => const MemberLedgerFailure(isOffline: true),
      _ => const MemberLedgerFailure(isOffline: false),
    };
  }
}
