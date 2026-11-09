import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/di/injection_container.dart' as di;
import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/router/app_router.dart';
import 'package:club_management_app/core/router/app_routes.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/club/data/datasources/club_fake_data_source.dart';
import 'package:club_management_app/features/courts/data/datasources/court_fake_data_source.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/courts/domain/entities/court_draft.dart';
import 'package:club_management_app/features/courts/presentation/screens/court_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_test_harness.dart';

class AnswerLostAfterSaving extends CourtFakeDataSource {
  AnswerLostAfterSaving() : super(latency: Duration.zero);

  @override
  Future<void> createCourt(CourtDraft draft) async {
    await super.createCourt(draft);
    throw ResponseTimeoutException('no answer');
  }
}

class FirstCreationLost extends CourtFakeDataSource {
  FirstCreationLost() : super(latency: Duration.zero);

  bool _lostOne = false;

  @override
  Future<void> createCourt(CourtDraft draft) async {
    if (_lostOne) return super.createCourt(draft);

    _lostOne = true;
    throw ResponseTimeoutException('no answer');
  }
}

class FirstCreationSavedLate extends CourtFakeDataSource {
  FirstCreationSavedLate() : super(latency: Duration.zero);

  CourtDraft? _unanswered;

  @override
  Future<void> createCourt(CourtDraft draft) async {
    final unanswered = _unanswered;
    if (unanswered == null) {
      _unanswered = draft;
      throw ResponseTimeoutException('no answer');
    }
    await super.createCourt(unanswered);

    return super.createCourt(draft);
  }
}

void main() {
  late CourtFakeDataSource courts;

  Future<void> openProfile(
    WidgetTester tester, {
    bool courtsEnabled = true,
    CourtFakeDataSource? source,
  }) async {
    courts = source ?? CourtFakeDataSource(latency: Duration.zero);
    await bootApp(
      tester,
      signedInAs: UserRole.admin,
      courtSource: courts,
      clubSource: ClubFakeDataSource(
        latency: Duration.zero,
        courtsEnabled: courtsEnabled,
      ),
    );
    di.sl<AppRouter>().router.go(AppRoutes.adminProfile);
    await tester.pumpAndSettle();
  }

  Future<void> openCourts(
    WidgetTester tester, {
    CourtFakeDataSource? source,
  }) async {
    await openProfile(tester, source: source);
    final access = find.text(AppStrings.adminCourtsTitle);
    await tester.ensureVisible(access);
    await tester.pumpAndSettle();
    await tester.tap(access);
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder inDialog(String label) => find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(label),
      );

  Future<void> fillNewCourt(WidgetTester tester, String name) async {
    await tester.tap(find.text(AppStrings.courtsNew));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.courtFormName),
      name,
    );
  }

  Future<void> chooseTime(
    WidgetTester tester,
    String label,
    String time,
  ) async {
    await tapVisible(
      tester,
      find.widgetWithText(DropdownButtonFormField<ClockTime>, label),
    );
    await tester.scrollUntilVisible(
      find.text(time),
      -96,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text(time));
    await tester.pumpAndSettle();
  }

  Future<int> storedCourtsNamed(WidgetTester tester, String name) async {
    final stored = await tester.runAsync(courts.fetchCourts);

    return stored!.where((court) => court.name == name).length;
  }

  testWidgets('the profile reaches courts when the club has them enabled', (
    tester,
  ) async {
    await openCourts(tester);

    expect(find.text('Cancha de Pádel 1'), findsOneWidget);
    expect(find.text('Pádel · De 08:00 a 23:00'), findsOneWidget);
  });

  testWidgets('the profile hides courts when the club has them disabled', (
    tester,
  ) async {
    await openProfile(tester, courtsEnabled: false);

    expect(find.text(AppStrings.adminCourtsTitle), findsNothing);
  });

  testWidgets('a deactivated court is marked and offers to reactivate', (
    tester,
  ) async {
    await openCourts(tester);

    expect(find.text(AppStrings.courtStatusInactive), findsOneWidget);

    await tester.tap(find.text(AppStrings.courtReactivateShort));
    await tester.pumpAndSettle();
    await tester.tap(inDialog(AppStrings.courtReactivateShort));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.courtReactivated), findsOneWidget);
    expect(find.text(AppStrings.courtStatusInactive), findsNothing);
  });

  testWidgets('creates a court with the default hours', (tester) async {
    await openCourts(tester);

    await tester.tap(find.text(AppStrings.courtsNew));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.courtFormName),
      'Cancha de Pádel 2',
    );
    await tapVisible(tester, find.text(AppStrings.courtFormCreate));

    expect(find.text(AppStrings.courtFormCreated), findsOneWidget);
    final stored = await tester.runAsync(courts.fetchCourts);
    final created = stored!.firstWhere((c) => c.name == 'Cancha de Pádel 2');
    expect(created.openingTime, const ClockTime(8, 0));
    expect(created.closingTime, const ClockTime(23, 0));
  });

  testWidgets('a blank name is explained in the field and never sent', (
    tester,
  ) async {
    await openCourts(tester);

    await tester.tap(find.text(AppStrings.courtsNew));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(AppStrings.courtFormCreate));

    expect(find.text(AppStrings.memberFormRequiredField), findsOneWidget);
    final stored = await tester.runAsync(courts.fetchCourts);
    expect(stored, hasLength(CourtFakeDataSource.seeded.length));
  });

  testWidgets('a repeated name is reported without losing the form', (
    tester,
  ) async {
    await openCourts(tester);

    await tester.tap(find.text(AppStrings.courtsNew));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.courtFormName),
      'cancha de tenis 1',
    );
    await tapVisible(tester, find.text(AppStrings.courtFormCreate));

    expect(find.text(AppStrings.courtFormConflict), findsOneWidget);
    expect(find.text('cancha de tenis 1'), findsOneWidget);
  });

  testWidgets('edits a court and returns to the updated list', (tester) async {
    await openCourts(tester);

    await tester.tap(find.text('Cancha de Tenis 1'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.courtFormName),
      'Cancha de Tenis Central',
    );
    await tapVisible(tester, find.text(AppStrings.courtFormSave));

    expect(find.text(AppStrings.courtFormUpdated), findsOneWidget);
    expect(find.byType(CourtFormScreen), findsNothing);
    expect(find.text('Cancha de Tenis Central'), findsOneWidget);
  });

  testWidgets('closing before opening is explained at once and never sent', (
    tester,
  ) async {
    await openCourts(tester);

    await fillNewCourt(tester, 'Cancha de Pádel 2');
    await chooseTime(tester, AppStrings.courtFormClosingTime, '07:30');

    expect(find.text(AppStrings.courtFormClosesBeforeOpening), findsOneWidget);

    await tapVisible(tester, find.text(AppStrings.courtFormCreate));

    expect(find.byType(CourtFormScreen), findsOneWidget);
    expect(await storedCourtsNamed(tester, 'Cancha de Pádel 2'), 0);
  });

  group('a creation the server did not answer in time', () {
    const name = 'Cancha de Pádel 2';

    testWidgets('a court created during a timeout ends as created', (
      tester,
    ) async {
      await openCourts(tester, source: AnswerLostAfterSaving());

      await fillNewCourt(tester, name);
      await tapVisible(tester, find.text(AppStrings.courtFormCreate));

      expect(find.text(AppStrings.courtFormCreated), findsOneWidget);
      expect(find.byType(CourtFormScreen), findsNothing);
      expect(find.text(name), findsOneWidget);
      expect(await storedCourtsNamed(tester, name), 1);
    });

    testWidgets(
        'a timeout that did not create the court asks to retry and creates once',
        (tester) async {
      await openCourts(tester, source: FirstCreationLost());

      await fillNewCourt(tester, name);
      await tapVisible(tester, find.text(AppStrings.courtFormCreate));

      expect(find.text(AppStrings.networkErrorMessage), findsOneWidget);
      expect(find.byType(CourtFormScreen), findsOneWidget);

      await tapVisible(tester, find.text(AppStrings.courtFormCreate));

      expect(find.text(AppStrings.courtFormCreated), findsOneWidget);
      expect(await storedCourtsNamed(tester, name), 1);
    });

    testWidgets('a retry that finds the first attempt saved ends as created', (
      tester,
    ) async {
      await openCourts(tester, source: FirstCreationSavedLate());

      await fillNewCourt(tester, name);
      await tapVisible(tester, find.text(AppStrings.courtFormCreate));
      await tapVisible(tester, find.text(AppStrings.courtFormCreate));

      expect(find.text(AppStrings.courtFormConflict), findsNothing);
      expect(find.text(AppStrings.courtFormCreated), findsOneWidget);
      expect(find.text(name), findsOneWidget);
      expect(await storedCourtsNamed(tester, name), 1);
    });
  });

  testWidgets('deactivates a court from its form after confirming', (
    tester,
  ) async {
    await openCourts(tester);

    await tester.tap(find.text('Cancha de Tenis 1'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(AppStrings.courtDeactivate));

    expect(
      find.textContaining(AppStrings.courtDeactivateCancels(1)),
      findsOneWidget,
    );

    await tester.tap(inDialog(AppStrings.courtDeactivate));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.courtDeactivated), findsOneWidget);
    expect(find.text(AppStrings.courtStatusInactive), findsNWidgets(2));
  });

  testWidgets('deactivating a court without reservations warns nothing more', (
    tester,
  ) async {
    await openCourts(tester);

    await tester.tap(find.text('Cancha de Pádel 1'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(AppStrings.courtDeactivate));

    expect(find.textContaining('También se cancela'), findsNothing);
  });
}
