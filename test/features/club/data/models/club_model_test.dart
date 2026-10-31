import 'package:club_management_app/features/club/data/models/club_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the reference fee in cents', () {
    final club = ClubModel.fromJson(const {
      'id': 1,
      'name': 'Club 1',
      'monthlyFeeAmount': 15000.5,
    });

    expect(club.name, 'Club 1');
    expect(club.monthlyFeeCents, 1500050);
  });

  test('a club without a reference fee is valid', () {
    final club = ClubModel.fromJson(const {
      'id': 1,
      'name': 'Club 1',
      'monthlyFeeAmount': null,
    });

    expect(club.hasMonthlyFee, isFalse);
  });

  test('sends whole pesos without decimals and null to clear', () {
    expect(ClubModel.bodyForMonthlyFee(1600000), {'monthlyFeeAmount': 16000});
    expect(ClubModel.bodyForMonthlyFee(1600050), {'monthlyFeeAmount': 16000.5});
    expect(ClubModel.bodyForMonthlyFee(null), {'monthlyFeeAmount': null});
  });
}
