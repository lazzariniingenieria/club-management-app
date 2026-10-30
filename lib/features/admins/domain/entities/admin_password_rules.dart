import 'dart:convert';

enum PasswordProblem { blank, tooShort, tooLong }

abstract final class AdminPasswordRules {
  static const int minLength = 8;
  static const int maxBytes = 72;

  static PasswordProblem? check(String password) {
    if (password.trim().isEmpty) return PasswordProblem.blank;
    if (password.length < minLength) return PasswordProblem.tooShort;
    if (utf8.encode(password).length > maxBytes) return PasswordProblem.tooLong;

    return null;
  }
}
