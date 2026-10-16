import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/billing_month.dart';
import '../../domain/entities/member_ledger.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/failures/payment_failures.dart';
import '../../domain/usecases/load_member_ledger_use_case.dart';
import '../../domain/usecases/register_payment_use_case.dart';
import '../formatting/peso_amount.dart';
import 'payment_form.dart';
import 'register_payment_state.dart';

class RegisterPaymentCubit extends Cubit<RegisterPaymentState> {
  final LoadMemberLedgerUseCase _loadLedger;
  final RegisterPaymentUseCase _registerPayment;
  final DateTime Function() _clock;

  RegisterPaymentCubit({
    required LoadMemberLedgerUseCase loadLedger,
    required RegisterPaymentUseCase registerPayment,
    DateTime Function() clock = DateTime.now,
  })  : _loadLedger = loadLedger,
        _registerPayment = registerPayment,
        _clock = clock,
        super(const RegisterPaymentLoading());

  bool _lastSubmitUnconfirmed = false;

  Future<void> open(int memberId) async {
    emit(const RegisterPaymentLoading());

    final result = await _loadLedger(memberId);
    if (isClosed) return;

    emit(result.fold(_unavailableFrom, _editingFor));
  }

  void toggleMonth(BillingMonth month) => _edit((form) => form.toggling(month));

  void showYear(int year) => _edit((form) => form.showingYear(year));

  void changeAmount(String text) =>
      _edit((form) => form.withAmount(PesoAmount.centsFrom(text)));

  void pickMethod(PaymentMethod method) =>
      _edit((form) => form.withMethod(method));

  void pickPayer(int? memberId) => _edit((form) => form.withPayer(memberId));

  Future<void> submit() async {
    final current = state;
    if (current is! RegisterPaymentEditing) return;
    if (current.isSubmitting || !current.form.canReview) return;

    final form = current.form;
    final retriesUnconfirmed = _lastSubmitUnconfirmed;
    _lastSubmitUnconfirmed = false;
    emit(RegisterPaymentEditing(form: form, isSubmitting: true));

    final result = await _registerPayment(form.toDraft());
    if (isClosed) return;

    await result.fold(
      (failure) => _recover(form, failure, retriesUnconfirmed),
      (_) async => emit(RegisterPaymentRegistered(form.toReceipt())),
    );
  }

  void _edit(PaymentForm Function(PaymentForm form) change) {
    final current = state;
    if (current is! RegisterPaymentEditing || current.isSubmitting) return;

    emit(
      RegisterPaymentEditing(
        form: change(current.form),
        notice: current.notice,
      ),
    );
  }

  Future<void> _recover(
    PaymentForm form,
    Failure failure,
    bool retriesUnconfirmed,
  ) async {
    switch (failure) {
      case AlreadyPaidMonthsFailure(:final months)
          when retriesUnconfirmed && _coversSelection(form, months):
        emit(RegisterPaymentRegistered(form.toReceipt()));
      case AlreadyPaidMonthsFailure(:final months):
        await _refresh(
          form.withoutMonths(months),
          MonthsAlreadyPaidNotice(months),
        );
      case ValidationFailure() when form.payerId != null:
        await _recoverFromRejectedPayer(form, failure);
      case ResponseTimeoutFailure():
        await _settleTimedOut(form);
      default:
        emit(_failedSubmitState(form, failure));
    }
  }

  Future<void> _refresh(
    PaymentForm form,
    RegisterPaymentNotice notice,
  ) async {
    final result = await _loadLedger(form.ledger.member.id);
    if (isClosed) return;

    emit(
      RegisterPaymentEditing(
        form: result.fold((_) => form, form.withLedger),
        notice: notice,
      ),
    );
  }

  Future<void> _recoverFromRejectedPayer(
    PaymentForm form,
    Failure failure,
  ) async {
    final result = await _loadLedger(form.ledger.member.id);
    if (isClosed) return;

    final refreshed = result.fold((_) => form, form.withLedger);
    final payerLeft = refreshed.payerId == null;

    emit(
      RegisterPaymentEditing(
        form: refreshed,
        notice: payerLeft
            ? const PayerLeftGroupNotice()
            : SubmitFailedNotice(failure.userMessage),
      ),
    );
  }

  Future<void> _settleTimedOut(PaymentForm form) async {
    final result = await _loadLedger(form.ledger.member.id);
    if (isClosed) return;

    emit(
      result.fold(
        (_) => _unconfirmed(form),
        (ledger) => _settledAgainst(form, ledger),
      ),
    );
  }

  RegisterPaymentState _unconfirmed(PaymentForm form) {
    _lastSubmitUnconfirmed = true;

    return RegisterPaymentEditing(
      form: form,
      notice: const PaymentUnconfirmedNotice(),
    );
  }

  RegisterPaymentState _editingFor(MemberLedger ledger) {
    if (!ledger.canRecordPayments) {
      return const RegisterPaymentUnavailable(isInactive: true);
    }

    return RegisterPaymentEditing(form: PaymentForm.start(ledger, _clock()));
  }

  static RegisterPaymentState _settledAgainst(
    PaymentForm form,
    MemberLedger ledger,
  ) {
    final landed = form.toDraft().monthsAlreadyIn(ledger.paidMonths);
    if (_coversSelection(form, landed)) {
      return RegisterPaymentRegistered(form.toReceipt());
    }

    return RegisterPaymentEditing(
      form: form.withLedger(ledger),
      notice: landed.isEmpty
          ? const PaymentTimedOutNotice()
          : MonthsAlreadyPaidNotice(landed),
    );
  }

  static bool _coversSelection(PaymentForm form, List<BillingMonth> months) {
    return months.isNotEmpty && months.toSet().containsAll(form.selectedMonths);
  }

  static RegisterPaymentState _failedSubmitState(
    PaymentForm form,
    Failure failure,
  ) {
    return switch (failure) {
      InactiveMemberFailure() =>
        const RegisterPaymentUnavailable(isInactive: true),
      NotFoundFailure() => const RegisterPaymentUnavailable(isMissing: true),
      NetworkFailure() =>
        RegisterPaymentEditing(form: form, notice: const OfflineNotice()),
      _ => RegisterPaymentEditing(
          form: form,
          notice: SubmitFailedNotice(failure.userMessage),
        ),
    };
  }

  static RegisterPaymentState _unavailableFrom(Failure failure) {
    return RegisterPaymentUnavailable(
      isOffline: failure is NetworkFailure,
      isMissing: failure is NotFoundFailure,
    );
  }
}
