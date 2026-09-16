import 'package:dio/dio.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String dni, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  final AppLogger logger;
  final int clubId;

  AuthRemoteDataSourceImpl(
    this.apiClient,
    this.logger, {
    this.clubId = AppEnvironment.clubId,
  });

  static const String _logContext = 'AuthRemoteDataSource';

  @override
  Future<AuthResponseModel> login(String dni, String password) async {
    try {
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        ApiConstants.login,
        data: {'clubId': clubId, 'dni': dni, 'password': password},
      );

      return _parse(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  AuthResponseModel _parse(Map<String, dynamic>? body) {
    if (body == null) {
      throw ServerException('Login response had an empty body');
    }

    try {
      return AuthResponseModel.fromJson(body);
    } on TypeError catch (error) {
      logger.error(
        'Login response did not match the expected contract',
        context: _logContext,
        cause: error,
      );
      throw ServerException('Login response did not match the contract');
    }
  }

  Exception _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;

    logger.error(
      'POST ${ApiConstants.login} for club $clubId failed with status '
      '$statusCode',
      context: _logContext,
      cause: error,
    );

    if (statusCode == 401) {
      return UnauthorizedException('Login rejected for club $clubId');
    }
    if (statusCode == 400) {
      return ValidationException('Login request rejected as invalid');
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
