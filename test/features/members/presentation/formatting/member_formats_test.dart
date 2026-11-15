import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:club_management_app/features/members/presentation/formatting/member_formats.dart';
import 'package:flutter_test/flutter_test.dart';

Member _member({String? dni}) => Member(
      id: 1,
      firstName: 'Juan',
      lastName: 'Pérez',
      status: MemberStatus.active,
      daysOverdue: 0,
      dni: dni,
    );

void main() {
  test('shows the dni grouped with dots', () {
    expect(MemberFormats.dni(_member(dni: '30111222')), 'DNI 30.111.222');
  });

  test('says so when the member has not given a dni', () {
    expect(MemberFormats.dni(_member()), 'Sin DNI');
  });
}
