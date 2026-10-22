import 'admin_remote_data_source.dart';

class AdminFakeDataSource implements AdminRemoteDataSource {
  AdminFakeDataSource({this.latency = const Duration(milliseconds: 600)});

  final Duration latency;

  @override
  Future<void> resetPassword(int adminId, String newPassword) async {
    await Future<void>.delayed(latency);
  }
}
