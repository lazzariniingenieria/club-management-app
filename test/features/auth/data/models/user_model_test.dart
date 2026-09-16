import 'package:club_management_app/features/auth/data/models/user_model.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> payloadWithRole(Object? role) => {
        'id': '42',
        'email': 'someone@club.com',
        'fullName': 'Alguien',
        'role': role,
      };

  group('UserModel.fromJson', () {
    test('maps the three roles the API can return', () {
      expect(
          UserModel.fromJson(payloadWithRole('MEMBER')).role, UserRole.member);
      expect(UserModel.fromJson(payloadWithRole('ADMIN')).role, UserRole.admin);
      expect(
        UserModel.fromJson(payloadWithRole('SUPER_ADMIN')).role,
        UserRole.superAdmin,
      );
    });

    test('is case insensitive on the role', () {
      expect(
        UserModel.fromJson(payloadWithRole('super_admin')).role,
        UserRole.superAdmin,
      );
    });

    test('falls back to the least privileged role on an unknown value', () {
      expect(
          UserModel.fromJson(payloadWithRole('OWNER')).role, UserRole.member);
      expect(UserModel.fromJson(payloadWithRole(null)).role, UserRole.member);
    });

    test('accepts a numeric id, which the API may serialize either way', () {
      final model = UserModel.fromJson(const {
        'id': 42,
        'email': 'someone@club.com',
        'fullName': 'Alguien',
        'role': 'ADMIN',
      });

      expect(model.id, '42');
    });
  });

  group('UserModel.toJson', () {
    test('round-trips every role', () {
      for (final role in UserRole.values) {
        final original = UserModel(
          id: '7',
          email: 'someone@club.com',
          fullName: 'Alguien',
          role: role,
        );

        expect(UserModel.fromJson(original.toJson()), original);
      }
    });
  });
}
