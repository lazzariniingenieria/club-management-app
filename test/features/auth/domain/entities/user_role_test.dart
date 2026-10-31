import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canManageAdmins', () {
    test('is the single control point for the super admin delta', () {
      expect(UserRole.superAdmin.canManageAdmins, isTrue);
      expect(UserRole.admin.canManageAdmins, isFalse);
      expect(UserRole.member.canManageAdmins, isFalse);
    });
  });

  group('usesAdminSurface', () {
    test('puts admin and super admin on the same shell', () {
      expect(UserRole.admin.usesAdminSurface, isTrue);
      expect(UserRole.superAdmin.usesAdminSurface, isTrue);
    });

    test('keeps the member out of the admin shell', () {
      expect(UserRole.member.usesAdminSurface, isFalse);
    });
  });

  test('both admin roles edit the club fee, a member does not', () {
    expect(UserRole.superAdmin.canEditClubFee, isTrue);
    expect(UserRole.admin.canEditClubFee, isTrue);
    expect(UserRole.member.canEditClubFee, isFalse);
  });

  test('both admin roles change their own password, a member does not', () {
    expect(UserRole.admin.canChangeOwnPassword, isTrue);
    expect(UserRole.superAdmin.canChangeOwnPassword, isTrue);
    expect(UserRole.member.canChangeOwnPassword, isFalse);
  });
}
