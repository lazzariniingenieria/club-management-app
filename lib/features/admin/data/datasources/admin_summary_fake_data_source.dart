import '../models/admin_summary_model.dart';
import 'admin_summary_remote_data_source.dart';

class AdminSummaryFakeDataSource implements AdminSummaryRemoteDataSource {
  AdminSummaryFakeDataSource({
    this.latency = const Duration(milliseconds: 600),
  });

  final Duration latency;

  static const AdminSummaryModel summary = AdminSummaryModel(
    activeMembers: 230,
    overdueMembers: 25,
  );

  @override
  Future<AdminSummaryModel> fetchSummary() async {
    await Future<void>.delayed(latency);

    return summary;
  }
}
