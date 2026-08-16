import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/storage_keys.dart';
import '../storage/secure_storage_service.dart';

const String _defaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api/v1',
);

class ApiClient {
  final Dio dio;
  final SecureStorageService secureStorage;

  ApiClient({
    required this.dio,
    required this.secureStorage,
    String baseUrl = _defaultBaseUrl,
  }) {
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 15);
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken =
              await secureStorage.getToken(StorageKeys.accessToken);
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          return handler.next(e);
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ));
    }
  }
}
