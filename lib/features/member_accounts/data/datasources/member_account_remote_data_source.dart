import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_contract_guard.dart';
import '../models/member_account_model.dart';

abstract class MemberAccountRemoteDataSource {
  Future<MemberAccountModel?> fetchAccount(int memberId);

  Future<MemberAccountModel> createAccount(int memberId, String password);

  Future<MemberAccountModel> resetPassword(int memberId, String newPassword);
}

class MemberAccountRemoteDataSourceImpl
    implements MemberAccountRemoteDataSource {
  MemberAccountRemoteDataSourceImpl(this._apiClient, this._logger);

  final ApiClient _apiClient;
  final AppLogger _logger;

  static const String _logContext = 'MemberAccountRemoteDataSource';
  static const int _noContent = 204;

  @override
  Future<MemberAccountModel?> fetchAccount(int memberId) {
    return _guard(() async {
      final response = await _apiClient.dio
          .get<Object?>(ApiConstants.memberAccount(memberId));
      if (response.statusCode == _noContent) return null;

      return MemberAccountModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<MemberAccountModel> createAccount(int memberId, String password) {
    return _write(
      () => _apiClient.dio.post<Map<String, dynamic>>(
        ApiConstants.memberAccount(memberId),
        data: MemberAccountModel.bodyForCreate(password),
      ),
    );
  }

  @override
  Future<MemberAccountModel> resetPassword(int memberId, String newPassword) {
    return _write(
      () => _apiClient.dio.patch<Map<String, dynamic>>(
        ApiConstants.memberAccountPassword(memberId),
        data: MemberAccountModel.bodyForReset(newPassword),
      ),
    );
  }

  Future<MemberAccountModel> _write(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) {
    return _guard(() async {
      final response = await _apiClient.sendWrite(request);

      return MemberAccountModel.fromJson(response.data ?? const {});
    });
  }

  Future<T> _guard<T>(Future<T> Function() run) =>
      guardContract(run, logger: _logger, logContext: _logContext);
}
