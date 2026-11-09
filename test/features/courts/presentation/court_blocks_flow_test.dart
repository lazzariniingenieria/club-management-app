import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/courts/data/datasources/court_block_fake_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

void main() {
  late CourtBlockFakeDataSource blocks;

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openBlocksOf(WidgetTester tester, String courtName) async {
    blocks = CourtBlockFakeDataSource(latency: Duration.zero);
    await bootApp(
      tester,
      signedInAs: UserRole.admin,
      courtBlockSource: blocks,
    );
    di.sl<AppRouter>().router.go(AppRoutes.adminProfile);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(AppStrings.adminCourtsTitle));
    await tester.tap(find.text(courtName));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(AppStrings.courtBlocksAction));
  }

  Finder inDialog(String label) => find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(label),
      );

  testWidgets('the court shows its upcoming blocks with their reason', (
    tester,
  ) async {
    await openBlocksOf(tester, 'Cancha de Pádel 1');

    expect(find.text('Cancha de Pádel 1'), findsOneWidget);
    expect(find.text(CourtBlockFakeDataSource.seededReason), findsOneWidget);
    expect(find.text(AppStrings.courtBlockRemove), findsOneWidget);
  });

  testWidgets('a court without blocks explains how to add one', (
    tester,
  ) async {
    await openBlocksOf(tester, 'Cancha de Tenis 1');

    expect(find.text(AppStrings.courtBlocksEmptyTitle), findsOneWidget);
    expect(find.text(AppStrings.courtBlocksNew), findsOneWidget);
  });

  testWidgets('blocks the whole day by default, from opening to closing', (
    tester,
  ) async {
    await openBlocksOf(tester, 'Cancha de Tenis 1');

    await tester.tap(find.text(AppStrings.courtBlocksNew));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(AppStrings.courtBlockFormSave));

    expect(find.text(AppStrings.courtBlockCreated), findsOneWidget);
    expect(find.text(AppStrings.courtBlockNoReason), findsOneWidget);
    final now = DateTime.now();
    final stored = await tester.runAsync(
      () => blocks.fetchBlocks(2, from: DateTime(now.year, now.month, now.day)),
    );
    expect(stored!.single.startsAt.hour, 8);
    expect(stored.single.endsAt.hour, 22);
  });

  testWidgets('removes a block after confirming', (tester) async {
    await openBlocksOf(tester, 'Cancha de Pádel 1');

    await tester.tap(find.text(AppStrings.courtBlockRemove));
    await tester.pumpAndSettle();
    await tester.tap(inDialog(AppStrings.courtBlockRemove));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.courtBlockRemoved), findsOneWidget);
    expect(find.text(AppStrings.courtBlocksEmptyTitle), findsOneWidget);
  });

  testWidgets('cancelling the confirmation keeps the block', (tester) async {
    await openBlocksOf(tester, 'Cancha de Pádel 1');

    await tester.tap(find.text(AppStrings.courtBlockRemove));
    await tester.pumpAndSettle();
    await tester.tap(inDialog(AppStrings.cancelAction));
    await tester.pumpAndSettle();

    expect(find.text(CourtBlockFakeDataSource.seededReason), findsOneWidget);
  });
}
