import 'package:club_management_app/core/theme/app_colors.dart';
import 'package:club_management_app/features/admin/presentation/widgets/quick_access_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<int Function()> pumpCard(
    WidgetTester tester, {
    bool isEnabled = true,
  }) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickAccessCard(
            label: 'Nuevo socio',
            variant: QuickAccessVariant.newMember,
            isEnabled: isEnabled,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    return () => taps;
  }

  testWidgets('a screen reader can open the card it announces as a button', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final taps = await pumpCard(tester);

    expect(
      tester.getSemantics(find.byType(QuickAccessCard)),
      isSemantics(label: 'Nuevo socio', isButton: true, hasTapAction: true),
    );

    tester.semantics.tap(find.semantics.byLabel('Nuevo socio'));
    expect(taps(), 1);

    semantics.dispose();
  });

  testWidgets('a card not ready yet still answers the tap, so it can explain', (
    tester,
  ) async {
    final taps = await pumpCard(tester, isEnabled: false);

    await tester.tap(find.byType(QuickAccessCard));

    expect(taps(), 1);
  });

  testWidgets('a card not ready yet is drawn as disabled', (tester) async {
    await pumpCard(tester, isEnabled: false);

    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(QuickAccessCard),
            matching: find.byType(Material),
          )
          .first,
    );

    expect(material.color, AppColors.disabledSurface);
  });
}
