import 'dart:convert';

import 'package:club_management_app/core/constants/storage_keys.dart';
import 'package:club_management_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:club_management_app/features/auth/data/models/user_model.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/in_memory_secure_storage.dart';

void main() {
  late InMemorySecureStorage storage;
  late AuthLocalDataSourceImpl dataSource;

  const user = UserModel(id: 12, memberId: 34, role: UserRole.admin);

  setUp(() {
    storage = InMemorySecureStorage();
    dataSource = AuthLocalDataSourceImpl(storage);
  });

  test('round-trips a saved session', () async {
    await dataSource.saveSession(accessToken: 'token', user: user);

    expect(await dataSource.hasSession(), isTrue);
    expect(await dataSource.readUser(), user);
    expect(storage.values[StorageKeys.accessToken], 'token');
  });

  test('reports no session when nothing is stored', () async {
    expect(await dataSource.hasSession(), isFalse);
    expect(await dataSource.readUser(), isNull);
  });

  test('invalidates a session written before the contract changed', () async {
    storage.values[StorageKeys.accessToken] = 'legacy-token';
    storage.values[StorageKeys.refreshToken] = 'legacy-refresh-token';
    storage.values[StorageKeys.currentUser] = jsonEncode(const {
      'id': 'usr_001',
      'email': 'admin@club.com',
      'fullName': 'Ana Gómez',
      'role': 'ADMIN',
    });

    expect(await dataSource.hasSession(), isFalse);
    expect(storage.values, isEmpty);
  });

  test('clearing a session wipes every key', () async {
    await dataSource.saveSession(accessToken: 'token', user: user);

    await dataSource.clearSession();

    expect(storage.values, isEmpty);
  });
}
