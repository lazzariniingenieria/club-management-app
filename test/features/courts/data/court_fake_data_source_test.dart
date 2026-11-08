import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/features/courts/data/datasources/court_fake_data_source.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/courts/domain/entities/court_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CourtFakeDataSource source;

  setUp(() => source = CourtFakeDataSource(latency: Duration.zero));

  test('a repeated name is a conflict even with other casing, like the API',
      () {
    expect(
      () => source.createCourt(const CourtDraft(name: 'cancha de pádel 1')),
      throwsA(isA<ConflictException>()),
    );
  });

  test('a court keeps its own name when edited', () async {
    await source.updateCourt(
      1,
      const CourtDraft(name: 'Cancha de Pádel 1', type: 'Pádel'),
    );

    final courts = await source.fetchCourts();

    expect(courts.firstWhere((court) => court.id == 1).type, 'Pádel');
  });

  test('a court that does not close after it opens is rejected', () {
    expect(
      () => source.createCourt(
        const CourtDraft(
          name: 'Cancha nueva',
          openingTime: ClockTime(22, 0),
          closingTime: ClockTime(22, 0),
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('deactivated courts stay in the list', () async {
    await source.setCourtActive(2, isActive: false);

    final courts = await source.fetchCourts();
    final deactivated = courts.firstWhere((court) => court.id == 2);

    expect(deactivated.isActive, isFalse);
    expect(deactivated.name, 'Cancha de Tenis 1');
  });
}
