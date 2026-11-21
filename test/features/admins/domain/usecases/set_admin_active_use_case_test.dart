import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/admins/domain/entities/admin.dart';
import 'package:club_management_app/features/admins/domain/repositories/admin_repository.dart';
import 'package:club_management_app/features/admins/domain/usecases/set_admin_active_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

const Admin unlinked = Admin(id: 2, dni: '11111111', isActive: true);
const Admin linked = Admin(id: 3, dni: '20000000', memberId: 1, isActive: true);

void main() {
  late MockAdminRepository repository;
  late SetAdminActiveUseCase setAdminActive;

  void failWith(Admin admin, Failure failure) {
    when(() => repository.setAdminActive(admin.id, isActive: false))
        .thenAnswer((_) async => Left(failure));
  }

  void listAdmins(List<Admin> admins) {
    when(() => repository.loadAdmins()).thenAnswer((_) async => Right(admins));
  }

  setUp(() {
    repository = MockAdminRepository();
    setAdminActive = SetAdminActiveUseCase(repository);
  });

  test('a timed out deactivation that went through counts as done', () async {
    failWith(unlinked, const ResponseTimeoutFailure());
    listAdmins([const Admin(id: 2, dni: '11111111', isActive: false)]);

    final result = await setAdminActive(unlinked, isActive: false);

    expect(result.isRight(), isTrue);
  });

  test('a timed out deactivation that did not go through fails', () async {
    failWith(unlinked, const ResponseTimeoutFailure());
    listAdmins([unlinked]);

    final result = await setAdminActive(unlinked, isActive: false);

    expect(result.getLeft().toNullable(), isA<ResponseTimeoutFailure>());
  });

  test('a linked admin gone from the list was kept as a member', () async {
    failWith(linked, const NotFoundFailure());
    listAdmins([unlinked]);

    final result = await setAdminActive(linked, isActive: false);

    expect(result.isRight(), isTrue);
  });

  test('an unlinked admin gone from the list is not done', () async {
    failWith(unlinked, const NotFoundFailure());
    listAdmins([]);

    final result = await setAdminActive(unlinked, isActive: false);

    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });

  test('a lost connection before sending is not rechecked', () async {
    failWith(linked, const NetworkFailure());

    final result = await setAdminActive(linked, isActive: false);

    expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    verifyNever(() => repository.loadAdmins());
  });
}
