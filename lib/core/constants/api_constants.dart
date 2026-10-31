abstract final class ApiConstants {
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String ownPassword = '/auth/me/password';

  static const String members = '/members';
  static const String payments = '/payments';
  static const String paymentBatch = '/payments/batch';
  static const String paymentDelinquency = '/payments/delinquency';
  static const String feeReceipts = '/payments/receipts';
  static const String currentClub = '/clubs/me';
  static const String familyGroups = '/family-groups';
  static const String admins = '/admins';

  static String member(int memberId) => '$members/$memberId';

  static String memberFamilyGroup(int memberId) =>
      '${member(memberId)}/family-group';

  static String admin(int adminId) => '$admins/$adminId';

  static String adminPassword(int adminId) => '${admin(adminId)}/password';

  static String adminDeactivation(int adminId) => '${admin(adminId)}/deactivate';

  static String adminReactivation(int adminId) => '${admin(adminId)}/reactivate';

  static String familyGroup(int familyGroupId) =>
      '$familyGroups/$familyGroupId';

  static String memberPaymentHistory(int memberId) =>
      '$payments/members/$memberId?includeVoided=true';

  static String paymentVoiding(int paymentId) => '$payments/$paymentId/void';

  static String memberDeactivation(int memberId) =>
      '${member(memberId)}/deactivate';

  static String memberReactivation(int memberId) =>
      '${member(memberId)}/reactivate';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration reportReceiveTimeout = Duration(seconds: 60);

  static const String acceptHeader = 'Accept';
  static const String pdfMediaType = 'application/pdf';

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer';
}
