import '../../../../core/constants/api_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list_reader.dart';
import '../../../../core/network/api_writer.dart';
import '../../domain/entities/admin_draft.dart';
import '../models/admin_model.dart';

abstract class AdminRemoteDataSource {
  Future<List<AdminModel>> fetchAdmins();

  Future<void> createAdmin(AdminDraft draft, String password);

  Future<void> updateAdmin(int adminId, AdminDraft draft);

  Future<void> setAdminActive(int adminId, {required bool isActive});

  Future<void> resetPassword(int adminId, String newPassword);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  AdminRemoteDataSourceImpl(ApiClient apiClient, AppLogger logger)
      : _reader = ApiListReader(
          apiClient: apiClient,
          logger: logger,
          logContext: _logContext,
        ),
        _writer = ApiWriter(
          apiClient: apiClient,
          logger: logger,
          logContext: _logContext,
        );

  final ApiListReader _reader;
  final ApiWriter _writer;

  static const String _logContext = 'AdminRemoteDataSource';

  @override
  Future<List<AdminModel>> fetchAdmins() {
    return _reader.readLists(
      paths: const [ApiConstants.admins],
      build: (responses) => [
        for (final row in responses.single)
          AdminModel.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<void> createAdmin(AdminDraft draft, String password) {
    return _writer.post(
      ApiConstants.admins,
      AdminModel.bodyForCreation(draft, password),
    );
  }

  @override
  Future<void> updateAdmin(int adminId, AdminDraft draft) {
    return _writer.patch(
      ApiConstants.admin(adminId),
      body: AdminModel.bodyFromDraft(draft),
    );
  }

  @override
  Future<void> setAdminActive(int adminId, {required bool isActive}) {
    return _writer.patch(
      isActive
          ? ApiConstants.adminReactivation(adminId)
          : ApiConstants.adminDeactivation(adminId),
    );
  }

  @override
  Future<void> resetPassword(int adminId, String newPassword) {
    return _writer.patch(
      ApiConstants.adminPassword(adminId),
      body: AdminModel.bodyForPassword(newPassword),
    );
  }
}
