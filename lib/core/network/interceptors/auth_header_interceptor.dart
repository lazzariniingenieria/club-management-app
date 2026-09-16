import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';
import '../../constants/storage_keys.dart';
import '../../storage/secure_storage_service.dart';

class AuthHeaderInterceptor extends Interceptor {
  final SecureStorageService secureStorage;

  AuthHeaderInterceptor(this.secureStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await secureStorage.getToken(StorageKeys.accessToken);

    if (accessToken != null) {
      options.headers[ApiConstants.authorizationHeader] =
          '${ApiConstants.bearerPrefix} $accessToken';
    }

    handler.next(options);
  }
}
