import 'dart:async';

import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/courts/data/datasources/court_block_fake_data_source.dart';
import 'package:club_management_app/features/courts/domain/entities/court_block_draft.dart';
import 'package:club_management_app/features/courts/presentation/screens/court_block_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

class AnswerLostAfterSaving extends CourtBlockFakeDataSource {
  AnswerLostAfterSaving() : super(latency: Duration.zero);

  @override
  Future<void> createBlock(int courtId, CourtBlockDraft draft) async {
    await super.createBlock(courtId, draft);
    throw ResponseTimeoutException('no answer');
  }
}

class CreationsLost extends CourtBlockFakeDataSource {
  CreationsLost() : super(latency: Duration.zero);

  @override
  Future<void> createBlock(int courtId, CourtBlockDraft draft) async =>
      throw ResponseTimeoutException('no answer');
}

class AnswerLostAfterRemoving extends CourtBlockFakeDataSource {
  AnswerLostAfterRemoving() : super(latency: Duration.zero);

  @override
  Future<void> removeBlock(int courtId, int blockId) async {
    await super.removeBlock(courtId, blockId);
    throw ResponseTimeoutException('no answer');
  }
}

class RemovalsLost extends CourtBlockFakeDataSource {
  RemovalsLost() : super(latency: Duration.zero);

  @override
  Future<void> removeBlock(int courtId, int blockId) async =>
      throw ResponseTimeoutException('no answer');
}

class HeldRemovals extends CourtBlockFakeDataSource {
  HeldRemovals() : super(latency: Duration.zero);

  final Completer<void> answer = Completer<void>();

  @override
  Future<void> removeBlock(int courtId, int blockId) async {
    await answer.future;

    return super.removeBlock(courtId, blockId);
  }
}

void main() {
  late CourtBlockFakeDataSource blocks;

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openBlocksOf(
    WidgetTester tester,
    String courtName, {
    CourtBlockFakeDataSource? source,
  }) async {
    blocks = source ?? CourtBlockFakeDataSource(latency: Duration.zero);
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

  testWidgets('removing shows it is working until the server answers', (
    tester,
  ) async {
    final held = HeldRemovals();
    await openBlocksOf(tester, 'Cancha de Pádel 1', source: held);

    await tester.tap(find.text(AppStrings.courtBlockRemove));
    await tester.pumpAndSettle();
    await tester.tap(inDialog(AppStrings.courtBlockRemove));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(AppStrings.courtBlockRemove), findsNothing);

    held.answer.complete();
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.courtBlockRemoved), findsOneWidget);
    expect(find.text(AppStrings.courtBlocksEmptyTitle), findsOneWidget);
  });

  testWidgets('after removing a block the next one can still be removed', (
    tester,
  ) async {
    final source = CourtBlockFakeDataSource(latency: Duration.zero);
    final nextYear = DateTime(DateTime.now().year + 1, 3, 10);
    await tester.runAsync(
      () => source.createBlock(
        CourtBlockFakeDataSource.seededCourtId,
        CourtBlockDraft(
          startsAt: nextYear.add(const Duration(hours: 9)),
          endsAt: nextYear.add(const Duration(hours: 11)),
          reason: 'Torneo',
        ),
      ),
    );
    await openBlocksOf(tester, 'Cancha de Pádel 1', source: source);

    await tester.tap(find.text(AppStrings.courtBlockRemove).first);
    await tester.pumpAndSettle();
    await tester.tap(inDialog(AppStrings.courtBlockRemove));
    await tester.pumpAndSettle();

    expect(find.text('Torneo'), findsOneWidget);
    expect(find.text(AppStrings.courtBlockRemove), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a screen reader hears which block each remove action removes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openBlocksOf(tester, 'Cancha de Pádel 1');

    expect(
      tester.getSemantics(
        find.bySemanticsLabel(
          RegExp(r'^Quitar el bloqueo: .+ de 08:00 a 12:00$'),
        ),
      ),
      isSemantics(isButton: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  group('a removal the server did not answer in time', () {
    Future<void> removeTheBlock(WidgetTester tester) async {
      await tester.tap(find.text(AppStrings.courtBlockRemove));
      await tester.pumpAndSettle();
      await tester.tap(inDialog(AppStrings.courtBlockRemove));
      await tester.pumpAndSettle();
    }

    testWidgets('a block removed during a timeout is gone without an error', (
      tester,
    ) async {
      await openBlocksOf(
        tester,
        'Cancha de Pádel 1',
        source: AnswerLostAfterRemoving(),
      );

      await removeTheBlock(tester);

      expect(find.text(AppStrings.networkErrorMessage), findsNothing);
      expect(find.text(AppStrings.courtBlocksEmptyTitle), findsOneWidget);
    });

    testWidgets('a block still listed after a timeout can be removed again', (
      tester,
    ) async {
      await openBlocksOf(tester, 'Cancha de Pádel 1', source: RemovalsLost());

      await removeTheBlock(tester);

      expect(find.text(AppStrings.networkErrorMessage), findsOneWidget);
      expect(find.text(CourtBlockFakeDataSource.seededReason), findsOneWidget);
      expect(find.text(AppStrings.courtBlockRemove), findsOneWidget);
    });
  });

  group('a block the server did not answer in time', () {
    Future<void> blockTheWholeDay(WidgetTester tester) async {
      await tester.tap(find.text(AppStrings.courtBlocksNew));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text(AppStrings.courtBlockFormSave));
    }

    testWidgets('a block saved during a timeout ends as blocked, only once', (
      tester,
    ) async {
      await openBlocksOf(
        tester,
        'Cancha de Tenis 1',
        source: AnswerLostAfterSaving(),
      );

      await blockTheWholeDay(tester);

      expect(find.text(AppStrings.courtBlockCreated), findsOneWidget);
      expect(find.byType(CourtBlockFormScreen), findsNothing);
      expect(find.text(AppStrings.courtBlockNoReason), findsOneWidget);
    });

    testWidgets('a timeout nobody could confirm never says it was not saved', (
      tester,
    ) async {
      await openBlocksOf(tester, 'Cancha de Tenis 1', source: CreationsLost());

      await blockTheWholeDay(tester);

      expect(find.text(AppStrings.courtBlockUnconfirmed), findsOneWidget);
      expect(find.text(AppStrings.networkErrorMessage), findsNothing);
      expect(find.byType(CourtBlockFormScreen), findsOneWidget);
    });
  });
}
