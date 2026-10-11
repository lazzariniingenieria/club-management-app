import '../../../../core/constants/api_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list_reader.dart';
import '../models/admin_summary_model.dart';

abstract class AdminSummaryRemoteDataSource {
  Future<AdminSummaryModel> fetchSummary();
}

class AdminSummaryRemoteDataSourceImpl implements AdminSummaryRemoteDataSource {
  AdminSummaryRemoteDataSourceImpl(ApiClient apiClient, AppLogger logger)
      : _reader = ApiListReader(
          apiClient: apiClient,
          logger: logger,
          logContext: 'AdminSummaryRemoteDataSource',
        );

  final ApiListReader _reader;

  @override
  Future<AdminSummaryModel> fetchSummary() {
    return _reader.readLists(
      paths: const [ApiConstants.members, ApiConstants.paymentDelinquency],
      build: (responses) => AdminSummaryModel.fromResponses(
        members: responses.first,
        delinquency: responses.last,
      ),
    );
  }
}
