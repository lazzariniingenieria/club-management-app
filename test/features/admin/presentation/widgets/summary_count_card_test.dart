import 'package:club_management_app/features/admin/presentation/widgets/summary_count_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a screen reader can open the card it announces as a button', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SummaryCountCard(
            label: 'Socios activos',
            count: 230,
            variant: SummaryCardVariant.activeMembers,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(SummaryCountCard)),
      isSemantics(
        label: 'Socios activos: 230',
        isButton: true,
        hasTapAction: true,
      ),
    );

    tester.semantics.tap(find.semantics.byLabel('Socios activos: 230'));
    expect(taps, 1);

    semantics.dispose();
  });
}
