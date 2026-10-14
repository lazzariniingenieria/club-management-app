import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/formatters/digit_layout_formatter.dart';
import '../../domain/entities/billing_month.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/failures/payment_failures.dart';
import '../../domain/usecases/load_member_ledger_use_case.dart';
import '../../domain/usecases/register_payment_use_case.dart';
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

  static const int maxAmountDigits = 8;

  Future<void> open(int memberId) async {
    emit(const RegisterPaymentLoading());

    final result = await _loadLedger(memberId);
    if (isClosed) return;

    emit(
      result.fold(
        _unavailableFrom,
        (ledger) => RegisterPaymentEditing(
          form: PaymentForm.start(ledger, _clock()),
        ),
      ),
    );
  }

  void toggleMonth(BillingMonth month) =>
      _edit((form) => form.toggling(month));

  void showYear(int year) => _edit((form) => form.showingYear(year));

  void changeAmount(String text) =>
      _edit((form) => form.withAmount(_centsFrom(text)));

  void pickMethod(PaymentMethod method) =>
      _edit((form) => form.withMethod(method));

  void pickPayer(int? memberId) => _edit((form) => form.withPayer(memberId));

  Future<void> submit() async {
    final current = state;
    if (current is! RegisterPaymentEditing) return;
    if (current.isSubmitting || !current.form.canReview) return;

    final form = current.form;
    emit(RegisterPaymentEditing(form: form, isSubmitting: true));

    final result = await _registerPayment(form.toDraft());
    if (isClosed) return;

    await result.fold(
      (failure) => _recover(form, failure),
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

  Future<void> _recover(PaymentForm form, Failure failure) async {
    switch (failure) {
      case AlreadyPaidMonthsFailure(:final months):
        await _refresh(
          form.withoutMonths(months),
          MonthsAlreadyPaidNotice(months),
        );
      case ValidationFailure() when form.payerId != null:
        await _refresh(form.withPayer(null), const PayerLeftGroupNotice());
      case NotFoundFailure():
        emit(const RegisterPaymentUnavailable(isMissing: true));
      case NetworkFailure():
        emit(
          RegisterPaymentEditing(form: form, notice: const OfflineNotice()),
        );
      default:
        emit(
          RegisterPaymentEditing(
            form: form,
            notice: SubmitFailedNotice(failure.userMessage),
          ),
        );
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

  static int? _centsFrom(String text) {
    final digits = DigitLayouts.digitsOf(text);
    if (digits.isEmpty) return null;

    return int.parse(digits) * 100;
  }

  static RegisterPaymentState _unavailableFrom(Failure failure) {
    return RegisterPaymentUnavailable(
      isOffline: failure is NetworkFailure,
      isMissing: failure is NotFoundFailure,
    );
  }
}
