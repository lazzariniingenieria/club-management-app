import '../../domain/entities/club.dart';

class ClubModel extends Club {
  const ClubModel({required super.id, required super.name, super.monthlyFeeCents});

  static const String _idKey = 'id';
  static const String _nameKey = 'name';
  static const String _monthlyFeeKey = 'monthlyFeeAmount';

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    final fee = json[_monthlyFeeKey] as num?;

    return ClubModel(
      id: (json[_idKey] as num).toInt(),
      name: json[_nameKey] as String,
      monthlyFeeCents: fee == null ? null : (fee * 100).round(),
    );
  }

  static Map<String, dynamic> bodyForMonthlyFee(int? monthlyFeeCents) {
    return {
      _monthlyFeeKey: monthlyFeeCents == null ? null : _amountOf(monthlyFeeCents),
    };
  }

  static num _amountOf(int cents) =>
      cents % 100 == 0 ? cents ~/ 100 : cents / 100;
}
