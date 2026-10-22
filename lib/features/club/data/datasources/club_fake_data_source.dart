import '../models/club_model.dart';
import 'club_remote_data_source.dart';

class ClubFakeDataSource implements ClubRemoteDataSource {
  ClubFakeDataSource({this.latency = const Duration(milliseconds: 600)});

  final Duration latency;
  int? _monthlyFeeCents = 1500000;

  static const int clubId = 1;
  static const String clubName = 'Club 1';

  @override
  Future<ClubModel> fetchClub() async {
    await Future<void>.delayed(latency);

    return _current();
  }

  @override
  Future<ClubModel> updateMonthlyFee(int? monthlyFeeCents) async {
    await Future<void>.delayed(latency);
    _monthlyFeeCents = monthlyFeeCents;

    return _current();
  }

  ClubModel _current() => ClubModel(
        id: clubId,
        name: clubName,
        monthlyFeeCents: _monthlyFeeCents,
      );
}
