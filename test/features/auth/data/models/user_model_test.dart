import 'package:club_management_app/features/auth/data/models/user_model.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> payloadWithRole(Object? role) => {
        'userAccountId': 42,
        'memberId': 34,
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

    test('reads userAccountId as the account id', () {
      expect(UserModel.fromJson(payloadWithRole('ADMIN')).id, 42);
    });

    test('keeps memberId null when the account has no member', () {
      final model = UserModel.fromJson(const {
        'userAccountId': 12,
        'memberId': null,
        'role': 'SUPER_ADMIN',
      });

      expect(model.memberId, isNull);
    });
  });

  group('UserModel.toJson', () {
    test('round-trips every role', () {
      for (final role in UserRole.values) {
        final original = UserModel(id: 7, memberId: 34, role: role);

        expect(UserModel.fromJson(original.toJson()), original);
      }
    });

    test('round-trips an account without a member', () {
      const original = UserModel(id: 7, memberId: null, role: UserRole.admin);

      expect(UserModel.fromJson(original.toJson()), original);
    });
  });
}
