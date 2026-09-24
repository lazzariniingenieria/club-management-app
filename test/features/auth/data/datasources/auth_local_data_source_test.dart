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

  Future<void> saveSession() => dataSource.saveSession(
        accessToken: 'token',
        refreshToken: 'refresh-token',
        user: user,
      );

  setUp(() {
    storage = InMemorySecureStorage();
    dataSource = AuthLocalDataSourceImpl(storage);
  });

  test('round-trips a saved session', () async {
    await saveSession();

    expect(await dataSource.hasSession(), isTrue);
    expect(await dataSource.readUser(), user);
    expect(storage.values[StorageKeys.accessToken], 'token');
  });

  test('keeps the refresh token the interceptor needs on a 401', () async {
    await saveSession();

    expect(storage.values[StorageKeys.refreshToken], 'refresh-token');
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

  test('invalidates a session saved when the refresh token was dropped',
      () async {
    storage.values[StorageKeys.accessToken] = 'token';
    storage.values[StorageKeys.currentUser] = jsonEncode(user.toJson());
    storage.values[StorageKeys.sessionSchemaVersion] = '2';

    expect(await dataSource.hasSession(), isFalse);
    expect(storage.values, isEmpty);
  });

  test('clearing a session wipes every key', () async {
    await saveSession();

    await dataSource.clearSession();

    expect(storage.values, isEmpty);
  });
}
