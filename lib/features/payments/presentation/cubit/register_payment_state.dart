import 'package:equatable/equatable.dart';

import '../../domain/entities/billing_month.dart';
import '../../domain/entities/payment_receipt.dart';
import 'payment_form.dart';

sealed class RegisterPaymentState extends Equatable {
  const RegisterPaymentState();

  @override
  List<Object?> get props => [];
}

class RegisterPaymentLoading extends RegisterPaymentState {
  const RegisterPaymentLoading();
}

class RegisterPaymentUnavailable extends RegisterPaymentState {
  final bool isOffline;
  final bool isMissing;
  final bool isInactive;

  const RegisterPaymentUnavailable({
    this.isOffline = false,
    this.isMissing = false,
    this.isInactive = false,
  });

  @override
  List<Object?> get props => [isOffline, isMissing, isInactive];
}

class RegisterPaymentEditing extends RegisterPaymentState {
  final PaymentForm form;
  final RegisterPaymentNotice? notice;
  final bool isSubmitting;

  const RegisterPaymentEditing({
    required this.form,
    this.notice,
    this.isSubmitting = false,
  });

  @override
  List<Object?> get props => [form, notice, isSubmitting];
}

class RegisterPaymentRegistered extends RegisterPaymentState {
  final PaymentReceipt receipt;

  const RegisterPaymentRegistered(this.receipt);

  @override
  List<Object?> get props => [receipt];
}

sealed class RegisterPaymentNotice extends Equatable {
  const RegisterPaymentNotice();

  @override
  List<Object?> get props => [];
}

class OfflineNotice extends RegisterPaymentNotice {
  const OfflineNotice();
}

class PaymentUnconfirmedNotice extends RegisterPaymentNotice {
  const PaymentUnconfirmedNotice();
}

class MonthsAlreadyPaidNotice extends RegisterPaymentNotice {
  final List<BillingMonth> months;

  const MonthsAlreadyPaidNotice(this.months);

  @override
  List<Object?> get props => [months];
}

class PayerLeftGroupNotice extends RegisterPaymentNotice {
  const PayerLeftGroupNotice();
}

class FamilyPaymentIncompleteNotice extends RegisterPaymentNotice {
  final List<int> registeredIds;
  final List<int> pendingIds;
  final bool mayHaveLanded;

  const FamilyPaymentIncompleteNotice({
    required this.registeredIds,
    required this.pendingIds,
    required this.mayHaveLanded,
  });

  @override
  List<Object?> get props => [registeredIds, pendingIds, mayHaveLanded];
}

class FamilyAlreadyPaidNotice extends RegisterPaymentNotice {
  const FamilyAlreadyPaidNotice();
}

class SubmitFailedNotice extends RegisterPaymentNotice {
  final String message;

  const SubmitFailedNotice(this.message);

  @override
  List<Object?> get props => [message];
}
