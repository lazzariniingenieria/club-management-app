import 'dart:typed_data';

import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/reports/presentation/export/report_file_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

class RecordingExporter implements ReportFileExporter {
  final shared = <String>[];

  @override
  Future<void> preview(Uint8List bytes, String fileName) async {}

  @override
  Future<void> share(Uint8List bytes, String fileName) async =>
      shared.add(fileName);
}

void main() {
  testWidgets('Pagos opens the report, which downloads and shares the PDF', (
    tester,
  ) async {
    await bootApp(tester, signedInAs: UserRole.admin);
    final exporter = RecordingExporter();
    di.sl.unregister<ReportFileExporter>();
    di.sl.registerLazySingleton<ReportFileExporter>(() => exporter);

    di.sl<AppRouter>().router.go(AppRoutes.adminPayments);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.reportTitle));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.reportGenerate));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.reportReadyTitle), findsOneWidget);

    await tester.ensureVisible(find.text(AppStrings.reportShare));
    await tester.tap(find.text(AppStrings.reportShare));
    await tester.pumpAndSettle();

    expect(exporter.shared, hasLength(1));
    expect(exporter.shared.single, startsWith('cuotas-cobradas-'));
  });
}
