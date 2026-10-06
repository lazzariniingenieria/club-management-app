import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../models/member_model.dart';

abstract class MemberRemoteDataSource {
  Future<List<MemberModel>> fetchMembers();
}

class MemberRemoteDataSourceImpl implements MemberRemoteDataSource {
  final ApiClient apiClient;
  final AppLogger logger;

  MemberRemoteDataSourceImpl(this.apiClient, this.logger);

  static const String _logContext = 'MemberRemoteDataSource';

  @override
  Future<List<MemberModel>> fetchMembers() async {
    try {
      final responses = await Future.wait([
        _fetchList(ApiConstants.members),
        _fetchList(ApiConstants.paymentDelinquency),
      ]);

      return MemberModel.listFromResponses(
        members: responses.first,
        delinquency: responses.last,
      );
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on TypeError catch (error) {
      logger.error(
        'Member response did not match the expected contract',
        context: _logContext,
        cause: error,
      );
      throw ServerException('Member response did not match the contract');
    }
  }

  Future<List<dynamic>> _fetchList(String path) async {
    final response = await apiClient.dio.get<List<dynamic>>(path);

    return response.data ?? const [];
  }

  Exception _mapDioException(DioException error) {
    logger.error(
      '${error.requestOptions.path} failed with status '
      '${error.response?.statusCode}',
      context: _logContext,
      cause: error,
    );

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
