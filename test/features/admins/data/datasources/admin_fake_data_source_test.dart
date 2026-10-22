import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/features/admins/data/datasources/admin_fake_data_source.dart';
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
}
