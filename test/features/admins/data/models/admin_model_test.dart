import 'package:club_management_app/features/admins/data/models/admin_model.dart';
import 'package:club_management_app/features/admins/domain/entities/admin_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps the "active" flag, not the member status enum', () {
    final admin = AdminModel.fromJson(const {
      'id': 12,
      'dni': '30222333',
      'email': null,
      'memberId': 5,
      'active': false,
    });

    expect(admin.isActive, isFalse);
    expect(admin.memberId, 5);
    expect(admin.email, isNull);
  });

  test('always sends memberId, so editing never unlinks by accident', () {
    final body = AdminModel.bodyFromDraft(
      const AdminDraft(dni: '30222333', memberId: 5),
    );

    expect(body, containsPair('memberId', 5));
    expect(body, containsPair('email', null));
  });

  test('sends memberId null on purpose to unlink', () {
    final body = AdminModel.bodyFromDraft(const AdminDraft(dni: '30222333'));

    expect(body.containsKey('memberId'), isTrue);
    expect(body['memberId'], isNull);
  });

  test('the creation body carries the initial password', () {
    final body = AdminModel.bodyForCreation(
      const AdminDraft(dni: '30222333'),
      's3cr3t123',
    );

    expect(body['password'], 's3cr3t123');
  });
}
