import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/features/admins/data/datasources/admin_fake_data_source.dart';
import 'package:club_management_app/features/admins/data/datasources/fake_user_account_store.dart';
import 'package:club_management_app/features/admins/domain/entities/admin_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AdminFakeDataSource source;

  setUp(() => source = AdminFakeDataSource(latency: Duration.zero));

  test('a repeated dni is a conflict, like the API', () {
    expect(
      () => source.createAdmin(const AdminDraft(dni: '11111111'), '12345678'),
      throwsA(isA<ConflictException>()),
    );
  });

  test('a member already linked to another account is a conflict', () {
    expect(
      () => source.createAdmin(
        const AdminDraft(dni: '40111222', memberId: 1),
        '12345678',
      ),
      throwsA(isA<ConflictException>()),
    );
  });

  test('deactivated admins stay in the list', () async {
    await source.setAdminActive(2, isActive: false);

    final admins = await source.fetchAdmins();
    final deactivated = admins.firstWhere((admin) => admin.id == 2);

    expect(deactivated.isActive, isFalse);
  });

  test('a deactivated admin linked to a member leaves the list', () async {
    await source.setAdminActive(3, isActive: false);

    final admins = await source.fetchAdmins();

    expect(admins.map((admin) => admin.id), isNot(contains(3)));
  });

  test('a deactivated admin linked to a member keeps its account', () async {
    await source.setAdminActive(3, isActive: false);

    final account = source.accounts.ofMember(1);

    expect(account?.role, FakeAccountRole.member);
    expect(account?.isActive, isTrue);
  });

  test('a promoted member joins the list with the same account', () async {
    await source.promoteMember(2);

    final admins = await source.fetchAdmins();
    final promoted = admins.firstWhere((admin) => admin.memberId == 2);

    expect(promoted.id, 40);
    expect(promoted.isActive, isTrue);
  });

  test('a member without a member account cannot be promoted', () {
    expect(
      () => source.promoteMember(1),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('a demoted admin is not found as an admin anymore', () async {
    await source.setAdminActive(3, isActive: false);

    expect(
      () => source.setAdminActive(3, isActive: false),
      throwsA(isA<NotFoundException>()),
    );
  });
}
