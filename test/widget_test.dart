import 'package:flutter_test/flutter_test.dart';
import 'package:club_management_app/main.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;

void main() {
  setUpAll(() async {
    await di.init();
  });

  testWidgets('App renders LoginScreen without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ClubManagementApp());
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
  });
}
