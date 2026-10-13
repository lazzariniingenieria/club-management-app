import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/features/auth/domain/entities/user.dart';
import 'package:club_management_app/features/members/data/datasources/member_fake_data_source.dart';
import 'package:club_management_app/shared/formatters/digit_layout_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/app_test_harness.dart';

void main() {
  final seededMember = MemberFakeDataSource.roster.first;

  Finder chip(String label, int count) =>
      find.text(AppStrings.withCount(label, count));

  Future<void> openPaymentsTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(AppStrings.adminTabPayments),
      ),
    );
    await settleSession(tester);
  }

  Future<void> bootRoster(WidgetTester tester) async {
    await bootApp(tester, signedInAs: UserRole.admin);
    await openPaymentsTab(tester);
  }

  Future<void> openCreationForm(WidgetTester tester) async {
    await bootRoster(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  Future<void> openEditionForm(WidgetTester tester) async {
    await bootRoster(tester);
    await tester.enterText(find.byType(TextField).first, seededMember.dni);
    await settleSession(tester);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
  }

  Future<void> fillIdentity(
    WidgetTester tester, {
    required String dni,
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ana');
    await tester.enterText(fields.at(1), 'Álvarez');
    await tester.enterText(fields.at(2), dni);
  }

  Finder field(int index) => find.byType(TextFormField).at(index);

  bool fieldHasFocus(WidgetTester tester, int index) {
    final editable = find.descendant(
      of: field(index),
      matching: find.byType(EditableText),
    );

    return tester.widget<EditableText>(editable).focusNode.hasFocus;
  }

  bool fieldIsOnScreen(WidgetTester tester, int index) {
    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    final fieldRect = tester.getRect(field(index));

    return fieldRect.top >= viewport.top && fieldRect.bottom <= viewport.bottom;
  }

  Future<void> crampTheScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 260);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
  }

  Future<void> submitFromTheBottom(WidgetTester tester, String label) async {
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(label),
      100,
      scrollable: find
          .descendant(of: find.byType(Form), matching: find.byType(Scrollable))
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  group('creating a member', () {
    testWidgets('the blue action opens an empty form', (tester) async {
      await openCreationForm(tester);

      expect(find.text(AppStrings.memberFormCreateTitle), findsWidgets);
      expect(find.byType(TextFormField), findsNWidgets(5));
      expect(find.text(AppStrings.memberFormSaveCreation), findsOneWidget);
    });

    testWidgets('an empty form explains what is missing instead of saving', (
      tester,
    ) async {
      await openCreationForm(tester);

      await tester.tap(find.text(AppStrings.memberFormSaveCreation));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormRequiredField), findsNWidgets(3));
      expect(find.text(AppStrings.memberFormCreateTitle), findsWidgets);
    });

    testWidgets('the dni and the phone are laid out while typing', (
      tester,
    ) async {
      await openCreationForm(tester);

      await tester.enterText(field(2), '30111222');
      await tester.enterText(field(3), '1155667788');
      await tester.pump();

      expect(find.text('30.111.222'), findsOneWidget);
      expect(find.text('115566-7788'), findsOneWidget);
    });

    testWidgets('the dni shown with dots is saved as plain digits', (
      tester,
    ) async {
      await openCreationForm(tester);

      await fillIdentity(tester, dni: '45999888');
      await tester.tap(find.text(AppStrings.memberFormSaveCreation));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '45999888');
      await settleSession(tester);

      expect(find.text('Ana Álvarez'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('a valid form adds the member to the roster', (tester) async {
      await openCreationForm(tester);

      await fillIdentity(tester, dni: '45999888');
      await tester.tap(find.text(AppStrings.memberFormSaveCreation));
      await tester.pumpAndSettle();

      expect(
        chip(
          AppStrings.adminPaymentsFilterAll,
          MemberFakeDataSource.totalMembers + 1,
        ),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('a dni the club already uses is shown on the field', (
      tester,
    ) async {
      await openCreationForm(tester);

      await fillIdentity(tester, dni: seededMember.dni);
      await tester.tap(find.text(AppStrings.memberFormSaveCreation));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormDniTaken), findsOneWidget);
      expect(find.text(AppStrings.memberFormSaveCreation), findsOneWidget);
    });

    testWidgets('leaving with something typed asks before discarding it', (
      tester,
    ) async {
      await openCreationForm(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Ana');
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormDiscardTitle), findsOneWidget);

      await tester.tap(find.text(AppStrings.memberFormKeepEditingAction));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormSaveCreation), findsOneWidget);
    });

    testWidgets('discarding the changes leaves the form', (tester) async {
      await openCreationForm(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Ana');
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.memberFormDiscardAction));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormSaveCreation), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('leaving an untouched form goes straight back', (
      tester,
    ) async {
      await openCreationForm(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormDiscardTitle), findsNothing);
      expect(find.text(AppStrings.memberFormSaveCreation), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  group('the hybrid validation', () {
    testWidgets('a field is judged when the admin leaves it, not while typing',
        (tester) async {
      await openCreationForm(tester);

      await tester.enterText(field(4), 'ana@club');
      await tester.pump();

      expect(find.text(AppStrings.memberFormMalformedEmail), findsNothing);

      await tester.tap(field(3));
      await tester.pump();

      expect(find.text(AppStrings.memberFormMalformedEmail), findsOneWidget);
    });

    testWidgets('an error clears as soon as the field becomes valid', (
      tester,
    ) async {
      await openCreationForm(tester);

      await tester.enterText(field(4), 'ana@club');
      await tester.tap(field(3));
      await tester.pump();
      await tester.enterText(field(4), 'ana@club.com');
      await tester.pump();

      expect(find.text(AppStrings.memberFormMalformedEmail), findsNothing);
    });

    Future<void> submitWithFirstNameOutOfSight(WidgetTester tester) async {
      await openCreationForm(tester);
      await tester.enterText(field(1), 'Álvarez');
      await tester.enterText(field(2), '30111222');
      await crampTheScreen(tester);

      await submitFromTheBottom(tester, AppStrings.memberFormSaveCreation);
    }

    testWidgets('a field scrolled out of sight still blocks the save', (
      tester,
    ) async {
      await submitWithFirstNameOutOfSight(tester);

      expect(find.text(AppStrings.memberFormCreateTitle), findsWidgets);
      expect(find.text(AppStrings.memberFormRequiredField), findsOneWidget);
    });

    testWidgets('submitting reveals and focuses the first field in error', (
      tester,
    ) async {
      await submitWithFirstNameOutOfSight(tester);

      expect(fieldIsOnScreen(tester, 0), isTrue);
      expect(fieldHasFocus(tester, 0), isTrue);
    });
  });

  group('editing a member', () {
    testWidgets('the pencil opens the form with the member already loaded', (
      tester,
    ) async {
      await openEditionForm(tester);

      expect(find.text(AppStrings.memberFormEditTitle), findsWidgets);
      expect(find.text(seededMember.firstName), findsOneWidget);
      expect(
        find.text(DigitLayouts.groupedByThousands(seededMember.dni)),
        findsOneWidget,
      );
      expect(find.text(AppStrings.memberFormSaveEdition), findsOneWidget);
    });

    testWidgets('saving an edit returns to the roster with the change', (
      tester,
    ) async {
      await openEditionForm(tester);

      await tester.enterText(field(0), 'Anabela');
      await tester.tap(find.text(AppStrings.memberFormSaveEdition));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormSaveEdition), findsNothing);
      expect(
        find.text('Anabela ${seededMember.lastName}'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('the logical delete names the member before running', (
      tester,
    ) async {
      await openEditionForm(tester);

      await tester.tap(find.text(AppStrings.memberDeactivateAction));
      await tester.pumpAndSettle();

      expect(
        find.text(
          AppStrings.memberDeactivateConfirmTitle(seededMember.fullName),
        ),
        findsOneWidget,
      );
    });

    testWidgets('confirming the logical delete returns to the roster', (
      tester,
    ) async {
      await openEditionForm(tester);

      await tester.tap(find.text(AppStrings.memberDeactivateAction));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(AppStrings.memberDeactivateAction),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memberFormSaveEdition), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('the back swipe on iOS', () {
    final iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

    Future<void> swipeFromTheEdge(WidgetTester tester) async {
      await tester.dragFrom(const Offset(4, 300), const Offset(500, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('asks before discarding what was typed', (tester) async {
      await openCreationForm(tester);
      await tester.enterText(field(0), 'Ana');
      await tester.pumpAndSettle();

      await swipeFromTheEdge(tester);

      expect(find.text(AppStrings.memberFormDiscardTitle), findsOneWidget);
    }, variant: iOS);

    testWidgets('goes straight back from an untouched form', (tester) async {
      await openCreationForm(tester);

      await swipeFromTheEdge(tester);

      expect(find.text(AppStrings.memberFormDiscardTitle), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    }, variant: iOS);
  });
}
