import 'package:club_management_app/features/admins/domain/entities/admin_password_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts between 8 and 100 characters, like the API', () {
    expect(AdminPasswordRules.check('12345678'), isNull);
    expect(AdminPasswordRules.check('a' * 100), isNull);
  });

  test('rejects a password made only of spaces, like @NotBlank', () {
    expect(AdminPasswordRules.check(' ' * 8), PasswordProblem.blank);
    expect(AdminPasswordRules.check(''), PasswordProblem.blank);
  });

  test('keeps spaces inside a password that is not blank', () {
    expect(AdminPasswordRules.check('abc 1234'), isNull);
    expect(AdminPasswordRules.check(' abc1234 '), isNull);
  });

  test('rejects shorter and longer passwords', () {
    expect(AdminPasswordRules.check('1234567'), PasswordProblem.tooShort);
    expect(AdminPasswordRules.check('a' * 101), PasswordProblem.tooLong);
  });
}
