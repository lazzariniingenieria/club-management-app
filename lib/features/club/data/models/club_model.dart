import '../../../../core/network/money_json.dart';
import '../../domain/entities/club.dart';

class ClubModel extends Club {
  const ClubModel({
    required super.id,
    required super.name,
    super.monthlyFeeCents,
    super.courtsEnabled,
  });

  static const String _idKey = 'id';
  static const String _nameKey = 'name';
  static const String _monthlyFeeKey = 'monthlyFeeAmount';
  static const String _courtsEnabledKey = 'courtsEnabled';

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    final fee = json[_monthlyFeeKey] as num?;

    return ClubModel(
      id: (json[_idKey] as num).toInt(),
      name: json[_nameKey] as String,
      monthlyFeeCents: fee == null ? null : centsFromJson(fee),
      courtsEnabled: json[_courtsEnabledKey] as bool? ?? false,
    );
  }

  static Map<String, dynamic> bodyForMonthlyFee(int? monthlyFeeCents) {
    return {
      _monthlyFeeKey:
          monthlyFeeCents == null ? null : amountToJson(monthlyFeeCents),
    };
  }
}
