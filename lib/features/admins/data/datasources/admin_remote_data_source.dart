import '../../../../core/constants/api_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_writer.dart';
import '../models/admin_model.dart';

abstract class AdminRemoteDataSource {
  Future<void> resetPassword(int adminId, String newPassword);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  AdminRemoteDataSourceImpl(ApiClient apiClient, AppLogger logger)
      : _writer = ApiWriter(
          apiClient: apiClient,
          logger: logger,
          logContext: _logContext,
        );

  final ApiWriter _writer;

  static const String _logContext = 'AdminRemoteDataSource';

  @override
  Future<void> resetPassword(int adminId, String newPassword) {
    return _writer.patch(
      ApiConstants.adminPassword(adminId),
      body: AdminModel.bodyForPassword(newPassword),
    );
  }
}
