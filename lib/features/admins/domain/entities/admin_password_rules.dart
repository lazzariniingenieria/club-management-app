enum PasswordProblem { blank, tooShort, tooLong }

abstract final class AdminPasswordRules {
  static const int minLength = 8;
  static const int maxLength = 100;

  static PasswordProblem? check(String password) {
    if (password.trim().isEmpty) return PasswordProblem.blank;
    if (password.length < minLength) return PasswordProblem.tooShort;
    if (password.length > maxLength) return PasswordProblem.tooLong;

    return null;
  }
}
