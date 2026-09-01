import 'dart:convert';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/auth_token.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveSession({required AuthToken token, required UserModel user});
  Future<UserModel?> readUser();
  Future<bool> hasSession();
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorageService secureStorage;

  AuthLocalDataSourceImpl(this.secureStorage);

  @override
  Future<void> saveSession({
    required AuthToken token,
    required UserModel user,
  }) async {
    await secureStorage.saveToken(StorageKeys.accessToken, token.accessToken);
    await secureStorage.saveToken(StorageKeys.refreshToken, token.refreshToken);
    await secureStorage.saveToken(
      StorageKeys.currentUser,
      jsonEncode(user.toJson()),
    );
  }

  @override
  Future<UserModel?> readUser() async {
    final rawUser = await secureStorage.getToken(StorageKeys.currentUser);
    if (rawUser == null) return null;

    try {
      return UserModel.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
    } on FormatException catch (error) {
      throw CacheException('Stored session is corrupted: ${error.message}');
    }
  }

  @override
  Future<bool> hasSession() async {
    final accessToken = await secureStorage.getToken(StorageKeys.accessToken);
    return accessToken != null;
  }

  @override
  Future<void> clearSession() => secureStorage.deleteAll();
}
