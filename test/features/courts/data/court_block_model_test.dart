import 'package:club_management_app/features/courts/data/models/court_block_model.dart';
import 'package:club_management_app/features/courts/domain/entities/court_block_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the range as the local time of the club', () {
    final block = CourtBlockModel.fromJson(const {
      'id': 8,
      'courtId': 3,
      'startsAt': '2026-08-03T08:00:00',
      'endsAt': '2026-08-05T23:59:00',
      'reason': 'Mantenimiento de superficie',
      'createdAt': '2026-07-30T12:00:00Z',
      'createdByUserId': 2,
    });

    expect(block.courtId, 3);
    expect(block.startsAt, DateTime(2026, 8, 3, 8));
    expect(block.endsAt, DateTime(2026, 8, 5, 23, 59));
    expect(block.startsAt.isUtc, isFalse);
  });

  test('a block without a reason is valid', () {
    final block = CourtBlockModel.fromJson(const {
      'id': 9,
      'courtId': 3,
      'startsAt': '2026-08-15T09:00:00',
      'endsAt': '2026-08-15T12:00:00',
      'reason': null,
    });

    expect(block.reason, isNull);
    expect(block.isWithinOneDay, isTrue);
  });

  test('sends the range without seconds nor time zone', () {
    final body = CourtBlockModel.bodyFromDraft(
      CourtBlockDraft(
        startsAt: DateTime(2026, 8, 3, 8),
        endsAt: DateTime(2026, 8, 5, 23, 59),
        reason: 'Torneo',
      ),
    );

    expect(body, {
      'startsAt': '2026-08-03T08:00',
      'endsAt': '2026-08-05T23:59',
      'reason': 'Torneo',
      'reservationIdsToCancel': <int>[],
    });
  });

  test('sends an empty reason as null', () {
    final body = CourtBlockModel.bodyFromDraft(
      CourtBlockDraft(
        startsAt: DateTime(2026, 8, 3, 8),
        endsAt: DateTime(2026, 8, 3, 9),
      ),
    );

    expect(body['reason'], isNull);
  });

  test('sends the reservations the admin agreed to cancel', () {
    final body = CourtBlockModel.bodyFromDraft(
      CourtBlockDraft(
        startsAt: DateTime(2026, 12, 1, 8),
        endsAt: DateTime(2026, 12, 3, 23),
      ).cancelling(const [45, 46]),
    );

    expect(body['reservationIdsToCancel'], [45, 46]);
  });

  test('asks for the blocks from a day as yyyy-MM-dd', () {
    expect(CourtBlockModel.dayToJson(DateTime(2026, 1, 5)), '2026-01-05');
  });
}
