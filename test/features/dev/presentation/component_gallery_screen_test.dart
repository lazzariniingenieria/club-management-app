import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/theme/app_theme.dart';
import 'package:club_management_app/features/dev/presentation/screens/component_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpGallery(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ComponentGalleryScreen(),
      ),
    );
  }

  testWidgets('renders every catalog section', (tester) async {
    await pumpGallery(tester);

    for (final section in const [
      'COLOR TOKENS',
      'TYPOGRAPHY',
      'SPACING',
      'RADIUS',
      'APPBUTTON',
      'APPTEXTFORMFIELD',
    ]) {
      await tester.scrollUntilVisible(find.text(section), 300);
      expect(find.text(section), findsOneWidget);
    }
  });

  testWidgets('toggles the password field between hidden and visible', (
    tester,
  ) async {
    await pumpGallery(tester);

    final toggle = find.byTooltip(AppStrings.passwordShowAction);
    await tester.scrollUntilVisible(toggle, 300);
    await tester.ensureVisible(toggle);
    await tester.pump();
    expect(find.text('Password obscured'), findsOneWidget);

    await tester.tap(toggle);
    await tester.pump();

    expect(find.text('Password visible'), findsOneWidget);
    expect(find.byTooltip(AppStrings.passwordHideAction), findsOneWidget);
  });
}
