abstract final class ApiConstants {
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer';
}
