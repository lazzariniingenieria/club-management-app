import 'package:club_management_app/features/admins/domain/entities/admin_password_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts from 8 characters up to 72 UTF-8 bytes, like the API', () {
    expect(AdminPasswordRules.check('12345678'), isNull);
    expect(AdminPasswordRules.check('a' * 72), isNull);
    expect(AdminPasswordRules.check('ñ' * 36), isNull);
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
    expect(AdminPasswordRules.check('a' * 73), PasswordProblem.tooLong);
  });

  test('counts accented letters as two bytes, like @MaxUtf8Bytes', () {
    expect(AdminPasswordRules.check('á' * 37), PasswordProblem.tooLong);
    expect(AdminPasswordRules.check('${'a' * 71}é'), PasswordProblem.tooLong);
  });
}
