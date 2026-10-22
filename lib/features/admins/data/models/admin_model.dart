abstract final class AdminModel {
  static const String newPasswordKey = 'newPassword';

  static Map<String, dynamic> bodyForPassword(String newPassword) =>
      {newPasswordKey: newPassword};
}
