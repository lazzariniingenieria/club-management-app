import 'package:club_management_app/features/auth/data/models/auth_response_model.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthResponseModel.fromJson', () {
    test('reads the flat login body the API returns', () {
      final response = AuthResponseModel.fromJson(const {
        'accessToken': 'eyJ.payload.signature',
        'refreshToken': 'eyJ.refresh.signature',
        'expiresIn': 3600,
        'userAccountId': 12,
        'role': 'ADMIN',
        'memberId': 34,
      });

      expect(response.accessToken, 'eyJ.payload.signature');
      expect(response.refreshToken, 'eyJ.refresh.signature');
      expect(response.user.id, 12);
      expect(response.user.role, UserRole.admin);
      expect(response.user.memberId, 34);
    });

    test('accepts an account with no member, as a SUPER_ADMIN always is', () {
      final response = AuthResponseModel.fromJson(const {
        'accessToken': 'eyJ.payload.signature',
        'refreshToken': 'eyJ.refresh.signature',
        'userAccountId': 1,
        'role': 'SUPER_ADMIN',
        'memberId': null,
      });

      expect(response.user.memberId, isNull);
      expect(response.user.role, UserRole.superAdmin);
    });

    test('rejects a body without a refresh token, which would kill the session',
        () {
      expect(
        () => AuthResponseModel.fromJson(const {
          'accessToken': 'eyJ.payload.signature',
          'userAccountId': 12,
          'role': 'ADMIN',
          'memberId': 34,
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
