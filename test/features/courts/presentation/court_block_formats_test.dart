import 'package:club_management_app/features/courts/domain/entities/court_block.dart';
import 'package:club_management_app/features/courts/presentation/formatting/court_block_formats.dart';
import 'package:flutter_test/flutter_test.dart';

CourtBlock block(DateTime startsAt, DateTime endsAt, {String? reason}) =>
    CourtBlock(
      id: 1,
      courtId: 1,
      startsAt: startsAt,
      endsAt: endsAt,
      reason: reason,
    );

void main() {
  test('names the day with its weekday in Spanish', () {
    expect(CourtBlockFormats.day(DateTime(2026, 8, 3)), 'lun 03/08/2026');
    expect(CourtBlockFormats.day(DateTime(2026, 8, 9)), 'dom 09/08/2026');
  });

  test('a block within one day fits in one line', () {
    final lines = CourtBlockFormats.range(
      block(DateTime(2026, 8, 15, 9), DateTime(2026, 8, 15, 12)),
    );

    expect(lines, ['Sáb 15/08/2026, de 09:00 a 12:00']);
  });

  test('a block of several days says where it starts and where it ends', () {
    final lines = CourtBlockFormats.range(
      block(DateTime(2026, 8, 3, 8), DateTime(2026, 8, 5, 23, 59)),
    );

    expect(lines, [
      'Desde el lun 03/08/2026, 08:00',
      'Hasta el mié 05/08/2026, 23:59',
    ]);
  });

  test('a block without a reason says so', () {
    final reason = CourtBlockFormats.reason(
      block(DateTime(2026, 8, 3, 8), DateTime(2026, 8, 3, 9)),
    );

    expect(reason, 'Sin motivo');
  });
}
