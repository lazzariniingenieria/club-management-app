import 'dart:convert';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveSession({
    required String accessToken,
    required UserModel user,
  });
  Future<UserModel?> readUser();
  Future<bool> hasSession();
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorageService secureStorage;

  AuthLocalDataSourceImpl(this.secureStorage);

  @override
  Future<void> saveSession({
    required String accessToken,
    required UserModel user,
  }) async {
    await secureStorage.saveToken(StorageKeys.accessToken, accessToken);
    await secureStorage.saveToken(
      StorageKeys.currentUser,
      jsonEncode(user.toJson()),
    );
    await secureStorage.saveToken(
      StorageKeys.sessionSchemaVersion,
      StorageKeys.currentSessionSchemaVersion,
    );
  }

  @override
  Future<UserModel?> readUser() async {
    final rawUser = await secureStorage.getToken(StorageKeys.currentUser);
    if (rawUser == null) return null;

    try {
      return UserModel.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
    } on FormatException catch (error) {
      throw CacheException('Stored session could not be read: $error');
    } on TypeError catch (error) {
      throw CacheException('Stored session could not be read: $error');
    }
  }

  @override
  Future<bool> hasSession() async {
    final accessToken = await secureStorage.getToken(StorageKeys.accessToken);
    if (accessToken == null) return false;

    if (await _storedSchemaIsCurrent()) return true;

    await clearSession();
    return false;
  }

  @override
  Future<void> clearSession() => secureStorage.deleteAll();

  Future<bool> _storedSchemaIsCurrent() async {
    final version =
        await secureStorage.getToken(StorageKeys.sessionSchemaVersion);
    return version == StorageKeys.currentSessionSchemaVersion;
  }
}
