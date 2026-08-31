import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';
import '../../constants/storage_keys.dart';
import '../../logging/app_logger.dart';
import '../../session/session_expiry_notifier.dart';
import '../../storage/secure_storage_service.dart';

class TokenRefreshInterceptor extends QueuedInterceptor {
  final Dio refreshClient;
  final SecureStorageService secureStorage;
  final SessionExpiryNotifier sessionExpiryNotifier;
  final AppLogger logger;

  TokenRefreshInterceptor({
    required this.refreshClient,
    required this.secureStorage,
    required this.sessionExpiryNotifier,
    required this.logger,
  });

  static const String _retriedFlag = 'token_refresh_retried';
  static const String _logContext = 'TokenRefreshInterceptor';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isRecoverable(err)) return handler.next(err);

    final refreshToken = await secureStorage.getToken(StorageKeys.refreshToken);
    if (refreshToken == null) {
      return _expireSession(err, handler, 'no refresh token stored');
    }

    final String? accessToken;
    try {
      accessToken = await _refreshTokens(refreshToken);
    } on DioException catch (error) {
      return _expireSession(err, handler, 'refresh rejected', cause: error);
    }

    if (accessToken == null) {
      return _expireSession(
          err, handler, 'refresh response had no access token');
    }

    try {
      handler.resolve(await _retry(err.requestOptions, accessToken));
    } on DioException catch (error) {
      handler.next(error);
    }
  }

  bool _isRecoverable(DioException err) {
    if (err.response?.statusCode != 401) return false;
    if (err.requestOptions.path == ApiConstants.refresh) return false;
    return err.requestOptions.extra[_retriedFlag] != true;
  }

  Future<String?> _refreshTokens(String refreshToken) async {
    final response = await refreshClient.post<Map<String, dynamic>>(
      ApiConstants.refresh,
      data: {'refreshToken': refreshToken},
    );

    final accessToken = response.data?['accessToken'] as String?;
    if (accessToken == null) return null;

    await secureStorage.saveToken(StorageKeys.accessToken, accessToken);

    final rotatedRefreshToken = response.data?['refreshToken'] as String?;
    if (rotatedRefreshToken != null) {
      await secureStorage.saveToken(
          StorageKeys.refreshToken, rotatedRefreshToken);
    }

    logger.info('Access token refreshed', context: _logContext);
    return accessToken;
  }

  Future<Response<dynamic>> _retry(
    RequestOptions options,
    String accessToken,
  ) {
    return refreshClient.fetch<dynamic>(
      options.copyWith(
        extra: {...options.extra, _retriedFlag: true},
        headers: {
          ...options.headers,
          ApiConstants.authorizationHeader:
              '${ApiConstants.bearerPrefix} $accessToken',
        },
      ),
    );
  }

  Future<void> _expireSession(
    DioException err,
    ErrorInterceptorHandler handler,
    String reason, {
    Object? cause,
  }) async {
    logger.error(
      'Session expired on ${err.requestOptions.path}: $reason',
      context: _logContext,
      cause: cause ?? err,
    );

    await secureStorage.deleteAll();
    sessionExpiryNotifier.notifySessionExpired();

    handler.next(err);
  }
}
