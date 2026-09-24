import 'package:club_management_app/features/admin/presentation/widgets/quick_access_card.dart';
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
          body: QuickAccessCard(
            label: 'Gestión de socios',
            variant: QuickAccessVariant.members,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(QuickAccessCard)),
      isSemantics(
        label: 'Gestión de socios',
        isButton: true,
        hasTapAction: true,
      ),
    );

    tester.semantics.tap(find.semantics.byLabel('Gestión de socios'));
    expect(taps, 1);

    semantics.dispose();
  });
}
