import 'package:club_management_app/features/admins/domain/entities/admin.dart';
import 'package:club_management_app/features/admins/domain/repositories/admin_repository.dart';
import 'package:club_management_app/features/admins/domain/usecases/load_admins_use_case.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/members/domain/repositories/member_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

class MockMemberRepository extends Mock implements MemberRepository {}

Member member(int id, String firstName, String lastName) => Member(
      id: id,
      firstName: firstName,
      lastName: lastName,
      dni: '${30000000 + id}',
      status: MemberStatus.active,
      daysOverdue: 0,
    );

void main() {
  test('sorts by the name on screen, unlinked ones by numeric dni', () async {
    final admins = MockAdminRepository();
    final members = MockMemberRepository();
    when(() => admins.loadAdmins()).thenAnswer(
      (_) async => const Right([
        Admin(id: 1, dni: '30111222', isActive: true),
        Admin(id: 2, dni: '20000001', memberId: 10, isActive: true),
        Admin(id: 3, dni: '9000000', isActive: true),
        Admin(id: 4, dni: '20000002', memberId: 11, isActive: true),
        Admin(id: 5, dni: '10000000', memberId: 12, isActive: false),
      ]),
    );
    when(() => members.loadMembers()).thenAnswer(
      (_) async => Right([
        member(10, 'Juan', 'Pérez'),
        member(11, 'Ana', 'Álvarez'),
        member(12, 'Carlos', 'Acosta'),
      ]),
    );

    final result = await LoadAdminsUseCase(admins: admins, members: members)();
    final ids = result.getRight().toNullable()!.admins.map((admin) => admin.id);

    expect(ids, [4, 2, 3, 1, 5]);
  });
}
