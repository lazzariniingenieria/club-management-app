import '../../../members/data/models/member_model.dart';
import '../../domain/entities/payment_precheck.dart';
import 'payment_model.dart';

class PaymentPrecheckModel extends PaymentPrecheck {
  const PaymentPrecheckModel({
    required super.isActive,
    required super.paidMonths,
  });

  factory PaymentPrecheckModel.fromResponses({
    required Map<String, dynamic> member,
    required List<dynamic> payments,
  }) {
    return PaymentPrecheckModel(
      isActive: MemberModel.fromJson(member).isActive,
      paidMonths: {
        for (final payment in PaymentModel.listFromJson(payments))
          if (!payment.isVoided) payment.month,
      },
    );
  }
}
