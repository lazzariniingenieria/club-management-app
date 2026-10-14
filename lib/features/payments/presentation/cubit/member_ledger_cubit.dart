import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/load_member_ledger_use_case.dart';
import '../../domain/usecases/void_payment_use_case.dart';
import 'member_ledger_state.dart';

class MemberLedgerCubit extends Cubit<MemberLedgerState> {
  final LoadMemberLedgerUseCase _loadLedger;
  final VoidPaymentUseCase _voidPayment;

  MemberLedgerCubit({
    required LoadMemberLedgerUseCase loadLedger,
    required VoidPaymentUseCase voidPayment,
  })  : _loadLedger = loadLedger,
        _voidPayment = voidPayment,
        super(const MemberLedgerLoading());

  int? _memberId;

  Future<void> load(int memberId) async {
    _memberId = memberId;
    if (state is! MemberLedgerReady) emit(const MemberLedgerLoading());

    final result = await _loadLedger(memberId);
    if (isClosed) return;

    emit(result.fold(_stateFor, MemberLedgerReady.new));
  }

  Future<void> reload() async {
    final memberId = _memberId;
    if (memberId != null) await load(memberId);
  }

  Future<Failure?> voidPayment(Payment payment, {String? reason}) async {
    final result = await _voidPayment(payment.id, reason: reason);
    final failure = result.fold<Failure?>((failure) => failure, (_) => null);

    if (failure == null || failure is ConflictFailure) await reload();

    return failure;
  }

  static MemberLedgerState _stateFor(Failure failure) {
    return switch (failure) {
      NotFoundFailure() => const MemberLedgerMissing(),
      NetworkFailure() => const MemberLedgerFailure(isOffline: true),
      _ => const MemberLedgerFailure(isOffline: false),
    };
  }
}
