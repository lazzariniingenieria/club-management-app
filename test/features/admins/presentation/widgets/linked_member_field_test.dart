import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/features/admins/presentation/widgets/linked_member_field.dart';
import 'package:club_management_app/features/members/domain/entities/member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Member member(int id, String lastName) => Member(
      id: id,
      firstName: 'Socio',
      lastName: lastName,
      dni: '${30000000 + id}',
      status: MemberStatus.active,
      daysOverdue: 0,
    );

void main() {
  late int? selected;

  Future<void> pumpField(
    WidgetTester tester, {
    required List<Member> members,
    Set<int> takenMemberIds = const {},
    int? selectedMemberId,
  }) async {
    selected = selectedMemberId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LinkedMemberField(
            members: members,
            takenMemberIds: takenMemberIds,
            selectedMemberId: selectedMemberId,
            onSelected: (memberId) => selected = memberId,
          ),
        ),
      ),
    );
  }

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.text(AppStrings.adminFormMember));
    await tester.pumpAndSettle();
  }

  testWidgets('builds only the members on screen of a long roster', (
    tester,
  ) async {
    final crowd = [
      for (var id = 1; id <= 300; id++)
        member(id, 'Apellido${id.toString().padLeft(3, '0')}'),
    ];
    await pumpField(tester, members: crowd);
    await openPicker(tester);

    final last = find.text('Socio Apellido300');
    expect(last, findsNothing);

    await tester.scrollUntilVisible(
      last,
      2000,
      scrollable: find.byType(Scrollable).last,
    );
    expect(last, findsOneWidget);
  });

  testWidgets('a member linked to another admin cannot be chosen', (
    tester,
  ) async {
    await pumpField(
      tester,
      members: [member(1, 'Acosta'), member(2, 'Benítez')],
      takenMemberIds: {2},
    );
    await openPicker(tester);

    final taken = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Socio Benítez'),
        matching: find.byType(ListTile),
      ),
    );
    expect(taken.enabled, isFalse);
    expect(find.text(AppStrings.adminFormMemberTaken), findsOneWidget);

    await tester.tap(find.text('Socio Acosta'));
    await tester.pumpAndSettle();
    expect(selected, 1);
  });

  testWidgets('searching narrows the list and "Sin vincular" unlinks', (
    tester,
  ) async {
    await pumpField(
      tester,
      members: [member(1, 'Acosta'), member(2, 'Benítez')],
      selectedMemberId: 1,
    );
    await openPicker(tester);

    await tester.enterText(find.byType(TextField), 'Beni');
    await tester.pump();
    expect(find.text('Socio Acosta'), findsNothing);
    expect(find.text('Socio Benítez'), findsOneWidget);

    await tester.tap(find.text(AppStrings.adminFormNoMember));
    await tester.pumpAndSettle();
    expect(selected, isNull);
  });
}
