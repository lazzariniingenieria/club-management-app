import '../../../../core/network/money_json.dart';
import '../../domain/entities/billing_month.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/payment_draft.dart';
import '../../domain/entities/payment_method.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.memberId,
    required super.amountCents,
    required super.month,
    required super.method,
    required super.paidAt,
    super.paidByMemberId,
    super.voidedAt,
    super.voidReason,
  });

  static const String _idKey = 'id';
  static const String _memberIdKey = 'memberId';
  static const String _paidByMemberIdKey = 'paidByMemberId';
  static const String _amountKey = 'amount';
  static const String _periodCoveredKey = 'periodCovered';
  static const String _periodsCoveredKey = 'periodsCovered';
  static const String _batchKey = 'payments';
  static const String _paymentMethodKey = 'paymentMethod';
  static const String _paidAtKey = 'paidAt';
  static const String _voidedAtKey = 'voidedAt';
  static const String _voidReasonKey = 'voidReason';
  static const String reasonKey = 'reason';

  static const Map<PaymentMethod, String> _methodCodes = {
    PaymentMethod.cash: 'CASH',
    PaymentMethod.transfer: 'TRANSFER',
    PaymentMethod.other: 'OTHER',
  };

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: (json[_idKey] as num).toInt(),
      memberId: (json[_memberIdKey] as num).toInt(),
      paidByMemberId: (json[_paidByMemberIdKey] as num?)?.toInt(),
      amountCents: centsFromJson(json[_amountKey] as num),
      month: BillingMonth.parse(json[_periodCoveredKey] as String),
      method: _methodFrom(json[_paymentMethodKey] as String),
      paidAt: DateTime.parse(json[_paidAtKey] as String),
      voidedAt: _instantFrom(json[_voidedAtKey] as String?),
      voidReason: json[_voidReasonKey] as String?,
    );
  }

  static List<PaymentModel> listFromJson(List<dynamic> rows) {
    return [
      for (final row in rows.cast<Map<String, dynamic>>())
        PaymentModel.fromJson(row),
    ];
  }

  static Map<String, dynamic> bodyFromDraft(PaymentDraft draft) {
    return {
      _memberIdKey: draft.memberId,
      _paidByMemberIdKey: draft.paidByMemberId,
      _amountKey: amountToJson(draft.amountCents),
      _periodsCoveredKey: [
        for (final month in BillingMonth.sorted(draft.months)) month.toIsoDay(),
      ],
      _paymentMethodKey: _methodCodes[draft.method],
    };
  }

  static Map<String, dynamic> bodyForBatch(List<PaymentDraft> drafts) {
    return {
      _batchKey: [for (final draft in drafts) bodyFromDraft(draft)],
    };
  }

  static PaymentMethod _methodFrom(String code) {
    for (final entry in _methodCodes.entries) {
      if (entry.value == code.toUpperCase()) return entry.key;
    }

    return PaymentMethod.other;
  }

  static DateTime? _instantFrom(String? isoInstant) =>
      isoInstant == null ? null : DateTime.parse(isoInstant);
}
