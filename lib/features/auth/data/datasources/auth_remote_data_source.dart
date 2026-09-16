import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  final AppLogger logger;

  AuthRemoteDataSourceImpl(this.apiClient, this.logger);

  static const String _logContext = 'AuthRemoteDataSource';

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      final body = response.data;
      if (body == null) {
        throw ServerException('Login response had an empty body');
      }

      return AuthResponseModel.fromJson(body);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Exception _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;

    logger.error(
      'POST ${ApiConstants.login} failed with status $statusCode',
      context: _logContext,
      cause: error,
    );

    if (statusCode == 401) {
      return UnauthorizedException('Invalid email or password');
    }
    if (_isConnectivityIssue(error)) {
      return NetworkException('Could not reach the server');
    }
    return ServerException(error.message ?? 'Unknown server error');
  }

  bool _isConnectivityIssue(DioException error) {
    return const {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    }.contains(error.type);
  }
}
