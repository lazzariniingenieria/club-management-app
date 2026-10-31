import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/formatters/peso_amount.dart';
import '../../domain/entities/billing_month.dart';
import '../../domain/entities/family_payment_outcome.dart';
import '../../domain/entities/family_payment_request.dart';
import '../../domain/entities/member_ledger.dart';
import '../../domain/entities/payment_draft.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/failures/payment_failures.dart';
import '../../domain/usecases/load_family_payment_status_use_case.dart';
import '../../domain/usecases/load_member_ledger_use_case.dart';
import '../../domain/usecases/register_family_payment_use_case.dart';
import '../../domain/usecases/register_payment_use_case.dart';
import 'family_payment.dart';
import 'payment_form.dart';
import 'register_payment_state.dart';

class RegisterPaymentCubit extends Cubit<RegisterPaymentState> {
  final LoadMemberLedgerUseCase _loadLedger;
  final RegisterPaymentUseCase _registerPayment;
  final LoadFamilyPaymentStatusUseCase _loadFamilyStatus;
  final RegisterFamilyPaymentUseCase _registerFamilyPayment;
  final DateTime Function() _clock;

  RegisterPaymentCubit({
    required LoadMemberLedgerUseCase loadLedger,
    required RegisterPaymentUseCase registerPayment,
    required LoadFamilyPaymentStatusUseCase loadFamilyStatus,
    required RegisterFamilyPaymentUseCase registerFamilyPayment,
    DateTime Function() clock = DateTime.now,
  })  : _loadLedger = loadLedger,
        _registerPayment = registerPayment,
        _loadFamilyStatus = loadFamilyStatus,
        _registerFamilyPayment = registerFamilyPayment,
        _clock = clock,
        super(const RegisterPaymentLoading());

  PaymentDraft? _unconfirmedDraft;
  _UnconfirmedFamilyPayment? _unconfirmedFamily;

  Future<void> open(int memberId, {bool forFamily = false}) async {
    emit(const RegisterPaymentLoading());

    final result = await _loadLedger(memberId);
    if (isClosed) return;

    emit(result.fold(_unavailableFrom, _editingFor));
    if (forFamily && _hasRelativesToCharge) {
      await payForFamily(enabled: true);
    }
  }

  bool get _hasRelativesToCharge {
    final current = state;

    return current is RegisterPaymentEditing &&
        current.form.activeRelatives.isNotEmpty;
  }

  void toggleMonth(BillingMonth month) =>
      _edit((form) => form.toggling(month));

  void showYear(int year) => _edit((form) => form.showingYear(year));

  void changeAmount(String text) =>
      _edit((form) => form.withAmount(PesoAmount.centsFrom(text)));

  void pickMethod(PaymentMethod method) =>
      _edit((form) => form.withMethod(method));

  void pickPayer(int? memberId) =>
      _edit((form) => form.withPayer(memberId));

  Future<void> payForFamily({required bool enabled}) async {
    if (!enabled) return _edit((form) => form.withFamily(null));

    _edit((form) => form.withFamily(const FamilyPayment()));
    await _refreshFamilyStatus();
  }

  Future<void> reloadFamilyStatus() async {
    _edit((form) => form.withFamily(form.family?.loading()));
    await _refreshFamilyStatus();
  }

  void toggleRelative(int memberId) =>
      _edit((form) => form.withFamily(form.family?.toggling(memberId)));

  Future<void> submit() async {
    final current = state;
    if (current is! RegisterPaymentEditing) return;
    if (current.isSubmitting || !current.form.canReview) return;
    if (current.form.paysForFamily) return _submitForFamily(current.form);

    final form = current.form;
    final retriesUnconfirmed = _unconfirmedDraft == form.toDraft();
    _unconfirmedDraft = null;
    emit(RegisterPaymentEditing(form: form, isSubmitting: true));

    final result = await _registerPayment(form.toDraft());
    if (isClosed) return;

    await result.fold(
      (failure) => _recover(form, failure, retriesUnconfirmed),
      (_) async => emit(RegisterPaymentRegistered(form.toReceipt())),
    );
  }

  Future<void> _refreshFamilyStatus() async {
    final current = state;
    if (current is! RegisterPaymentEditing) return;

    final result = await _loadFamilyStatus(current.form.familyStatusIds);
    if (isClosed) return;

    _edit(
      (form) => form.withFamily(
        result.fold(
          (_) => form.family?.failed(),
          (statuses) => form.family?.loaded(statuses),
        ),
      ),
    );
  }

  Future<void> _submitForFamily(PaymentForm form) async {
    final request = form.toFamilyRequest();
    final previous = _unconfirmedFamily?.request == request
        ? _unconfirmedFamily
        : null;
    _unconfirmedFamily = null;
    emit(RegisterPaymentEditing(form: form, isSubmitting: true));

    final outcome = await _registerFamilyPayment(request);
    if (isClosed) return;

    switch (outcome) {
      case FamilyPaymentRegistered(:final months, :final skippedIds):
        emit(
          RegisterPaymentRegistered(
            form.toFamilyReceipt(months, skippedIds: skippedIds),
          ),
        );
      case FamilyPaymentNothingToCharge():
        await _settleNothingToCharge(form, previous);
      case FamilyPaymentUnconfirmed():
        _unconfirmedFamily = _UnconfirmedFamilyPayment(request, outcome);
        emit(
          RegisterPaymentEditing(
            form: form,
            notice: const PaymentUnconfirmedNotice(),
          ),
        );
      case FamilyPaymentRejected(:final failure):
        await _recoverFromRejectedFamily(form, failure, previous);
    }
  }

  Future<void> _settleNothingToCharge(
    PaymentForm form,
    _UnconfirmedFamilyPayment? previous,
  ) async {
    if (previous != null) return emit(_registeredFrom(form, previous));

    final settled = await _withFamilyHistory(form);
    if (isClosed) return;

    emit(
      RegisterPaymentEditing(
        form: settled,
        notice: const FamilyAlreadyPaidNotice(),
      ),
    );
  }

  Future<void> _recoverFromRejectedFamily(
    PaymentForm form,
    Failure failure,
    _UnconfirmedFamilyPayment? previous,
  ) async {
    switch (failure) {
      case ConflictFailure():
        await _recoverFromCollectedMonths(form, previous);
      case ValidationFailure():
        await _recoverFromChangedGroup(form, failure);
      default:
        emit(_failedSubmitState(form, failure));
    }
  }

  Future<void> _recoverFromCollectedMonths(
    PaymentForm form,
    _UnconfirmedFamilyPayment? previous,
  ) async {
    final settled = await _withFamilyHistory(form);
    if (isClosed) return;

    final nothingLeft = settled.feeCount == 0;
    if (nothingLeft && previous != null) {
      return emit(_registeredFrom(settled, previous));
    }

    emit(
      RegisterPaymentEditing(
        form: settled,
        notice: nothingLeft
            ? const FamilyAlreadyPaidNotice()
            : const FamilyMonthsCollectedNotice(),
      ),
    );
  }

  Future<void> _recoverFromChangedGroup(
    PaymentForm sent,
    Failure failure,
  ) async {
    final result = await _loadLedger(sent.ledger.member.id);
    if (isClosed) return;

    final regrouped = result.fold((_) => sent, sent.withGroupFrom);
    final left = sent.relativesMissingIn(regrouped);
    final payerLeft = sent.payerId != null && regrouped.payerId == null;
    final settled = await _withFamilyHistory(regrouped);
    if (isClosed) return;

    emit(
      RegisterPaymentEditing(
        form: settled,
        notice: left.isEmpty && !payerLeft
            ? SubmitFailedNotice(failure.userMessage)
            : FamilyGroupChangedNotice(
                leftNames: [for (final relative in left) relative.fullName],
                payerLeft: payerLeft,
              ),
      ),
    );
  }

  Future<PaymentForm> _withFamilyHistory(PaymentForm form) async {
    final history = await _loadFamilyStatus(form.familyStatusIds);

    return history.fold((_) => form, form.withFamilyHistory);
  }

  static RegisterPaymentState _registeredFrom(
    PaymentForm form,
    _UnconfirmedFamilyPayment unconfirmed,
  ) {
    return RegisterPaymentRegistered(
      form.toFamilyReceipt(
        unconfirmed.outcome.months,
        skippedIds: unconfirmed.outcome.skippedIds,
      ),
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
    _unconfirmedDraft = form.toDraft();

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

  RegisterPaymentState _settledAgainst(PaymentForm form, MemberLedger ledger) {
    final landed = form.toDraft().monthsAlreadyIn(ledger.paidMonths);
    if (_coversSelection(form, landed)) {
      return RegisterPaymentRegistered(form.toReceipt());
    }

    final refreshed = form.withLedger(ledger);
    _unconfirmedDraft = refreshed.toDraft();

    return RegisterPaymentEditing(
      form: refreshed,
      notice: landed.isEmpty
          ? const PaymentUnconfirmedNotice()
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

class _UnconfirmedFamilyPayment {
  final FamilyPaymentRequest request;
  final FamilyPaymentUnconfirmed outcome;

  const _UnconfirmedFamilyPayment(this.request, this.outcome);
}
