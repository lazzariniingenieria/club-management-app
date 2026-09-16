import 'dart:convert';

import 'package:club_management_app/core/constants/storage_keys.dart';
import 'package:club_management_app/core/storage/secure_storage_service.dart';
import 'package:club_management_app/features/auth/data/models/user_model.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';

class InMemorySecureStorage implements SecureStorageService {
  final Map<String, String> values = {};

  void seedSession(UserRole role) {
    values[StorageKeys.accessToken] = 'seeded-access-token';
    values[StorageKeys.refreshToken] = 'seeded-refresh-token';
    values[StorageKeys.currentUser] = jsonEncode(
      UserModel(
        id: 'seeded-${role.name}',
        email: '${role.name}@club.com',
        fullName: 'Seeded ${role.name}',
        role: role,
      ).toJson(),
    );
  }

  @override
  Future<String?> getToken(String key) async => values[key];

  @override
  Future<void> saveToken(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> deleteToken(String key) async {
    values.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    values.clear();
  }
}
