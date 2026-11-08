import 'package:club_management_app/features/courts/data/models/court_model.dart';
import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/courts/domain/entities/court_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the hours the API sends with seconds', () {
    final court = CourtModel.fromJson(const {
      'id': 3,
      'name': 'Cancha de Pádel 1',
      'type': 'Pádel',
      'openingTime': '08:00:00',
      'closingTime': '23:30:00',
      'active': true,
    });

    expect(court.id, 3);
    expect(court.openingTime, const ClockTime(8, 0));
    expect(court.closingTime, const ClockTime(23, 30));
    expect(court.isActive, isTrue);
  });

  test('a court without a sport and deactivated is valid', () {
    final court = CourtModel.fromJson(const {
      'id': 4,
      'name': 'Cancha 2',
      'type': null,
      'openingTime': '09:00:00',
      'closingTime': '22:00:00',
      'active': false,
    });

    expect(court.type, isNull);
    expect(court.isActive, isFalse);
  });

  test('sends the hours as HH:mm with leading zeros', () {
    final body = CourtModel.bodyFromDraft(
      const CourtDraft(
        name: 'Cancha 1',
        type: 'Tenis',
        openingTime: ClockTime(7, 5),
        closingTime: ClockTime(23, 59),
      ),
    );

    expect(body, {
      'name': 'Cancha 1',
      'type': 'Tenis',
      'openingTime': '07:05',
      'closingTime': '23:59',
    });
  });

  test('sends an empty sport as null, since PATCH replaces every field', () {
    final body = CourtModel.bodyFromDraft(const CourtDraft(name: 'Cancha 1'));

    expect(body.containsKey('type'), isTrue);
    expect(body['type'], isNull);
  });
}
