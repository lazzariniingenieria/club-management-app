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
        account.dni,
        AuthFakeDataSource.sharedPassword,
      );

      expect(response.user, account.user);
      expect(response.accessToken, isNotEmpty);
    }
  });

  test('covers both branches of the nullable memberId', () {
    final memberIds =
        AuthFakeDataSource.accounts.map((a) => a.user.memberId).toList();

    expect(memberIds, contains(isNull));
    expect(memberIds, contains(isNotNull));
  });

  test('ignores surrounding spaces in the DNI', () async {
    final response = await dataSource.login(
      '  11111111 ',
      AuthFakeDataSource.sharedPassword,
    );

    expect(response.user.role, UserRole.admin);
  });

  test('rejects a wrong password', () {
    expect(
      () => dataSource.login('11111111', 'wrong-password'),
      throwsA(isA<UnauthorizedException>()),
    );
  });

  test('rejects an unknown account', () {
    expect(
      () => dataSource.login('00000000', AuthFakeDataSource.sharedPassword),
      throwsA(isA<UnauthorizedException>()),
    );
  });
}
