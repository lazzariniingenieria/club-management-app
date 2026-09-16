import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/features/auth/data/datasources/auth_fake_data_source.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dataSource = AuthFakeDataSource(latency: Duration.zero);

  test('offers one account per role so the guards can be exercised', () {
    final roles = AuthFakeDataSource.accounts.map((a) => a.user.role).toSet();

    expect(roles, UserRole.values.toSet());
  });

  test('signs in each seeded account with the shared password', () async {
    for (final account in AuthFakeDataSource.accounts) {
      final response = await dataSource.login(
        account.email,
        AuthFakeDataSource.sharedPassword,
      );

      expect(response.user, account.user);
      expect(response.token.accessToken, isNotEmpty);
    }
  });

  test('ignores casing and surrounding spaces in the email', () async {
    final response = await dataSource.login(
      '  ADMIN@Club.com ',
      AuthFakeDataSource.sharedPassword,
    );

    expect(response.user.role, UserRole.admin);
  });

  test('rejects a wrong password', () {
    expect(
      () => dataSource.login('admin@club.com', 'wrong-password'),
      throwsA(isA<UnauthorizedException>()),
    );
  });

  test('rejects an unknown account', () {
    expect(
      () => dataSource.login(
          'nobody@club.com', AuthFakeDataSource.sharedPassword),
      throwsA(isA<UnauthorizedException>()),
    );
  });
}
