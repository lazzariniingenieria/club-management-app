import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_environment.dart';
import '../constants/api_constants.dart';
import '../logging/app_logger.dart';
import '../session/session_expiry_notifier.dart';
import '../storage/secure_storage_service.dart';
import 'interceptors/auth_header_interceptor.dart';
import 'interceptors/token_refresh_interceptor.dart';

class ApiClient {
  final Dio dio;

  ApiClient({
    required this.dio,
    required Dio refreshClient,
    required SecureStorageService secureStorage,
    required SessionExpiryNotifier sessionExpiryNotifier,
    required AppLogger logger,
    String baseUrl = AppEnvironment.apiBaseUrl,
  }) {
    _applyOptions(dio, baseUrl);
    _applyOptions(refreshClient, baseUrl);

    dio.interceptors.add(AuthHeaderInterceptor(secureStorage));
    dio.interceptors.add(
      TokenRefreshInterceptor(
        refreshClient: refreshClient,
        secureStorage: secureStorage,
        sessionExpiryNotifier: sessionExpiryNotifier,
        logger: logger,
      ),
    );

    if (kDebugMode) dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  static void _applyOptions(Dio client, String baseUrl) {
    client.options
      ..baseUrl = baseUrl
      ..connectTimeout = ApiConstants.connectTimeout
      ..receiveTimeout = ApiConstants.receiveTimeout
      ..headers = Map<String, String>.from(ApiConstants.defaultHeaders);
  }
}
