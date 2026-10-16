abstract final class ApiConstants {
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';

  static const String members = '/members';
  static const String payments = '/payments';
  static const String paymentDelinquency = '/payments/delinquency';
  static const String currentClub = '/clubs/me';

  static String member(int memberId) => '$members/$memberId';

  static String memberPaymentHistory(int memberId) =>
      '$payments/members/$memberId?includeVoided=true';

  static String paymentVoiding(int paymentId) => '$payments/$paymentId/void';

  static String memberDeactivation(int memberId) =>
      '${member(memberId)}/deactivate';

  static String memberReactivation(int memberId) =>
      '${member(memberId)}/reactivate';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer';
}
