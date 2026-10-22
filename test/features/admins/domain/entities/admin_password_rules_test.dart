import 'package:club_management_app/features/admins/domain/entities/admin_password_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts between 8 and 100 characters, like the API', () {
    expect(AdminPasswordRules.check('12345678'), isNull);
    expect(AdminPasswordRules.check('a' * 100), isNull);
  });

  test('rejects shorter and longer passwords', () {
    expect(AdminPasswordRules.check('1234567'), PasswordProblem.tooShort);
    expect(AdminPasswordRules.check('a' * 101), PasswordProblem.tooLong);
  });
}
