import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/courts/presentation/widgets/court_time_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offers every half hour of the day to open', () {
    final options = CourtTimeField.openingOptions(const ClockTime(8, 0));

    expect(options, hasLength(48));
    expect(options.first, const ClockTime(0, 0));
    expect(options.last, const ClockTime(23, 30));
  });

  test('lets a court close at the last minute of the day', () {
    final options = CourtTimeField.closingOptions(const ClockTime(23, 0));

    expect(options.last, ClockTime.lastMinuteOfDay);
  });

  test('never offers to close at midnight, which is before any opening', () {
    final options = CourtTimeField.closingOptions(const ClockTime(23, 0));

    expect(options, isNot(contains(const ClockTime(0, 0))));
    expect(options.first, const ClockTime(0, 30));
  });

  test('keeps a stored time off the half hour, in order', () {
    final options = CourtTimeField.openingOptions(const ClockTime(8, 15));

    final index = options.indexOf(const ClockTime(8, 15));
    expect(options[index - 1], const ClockTime(8, 0));
    expect(options[index + 1], const ClockTime(8, 30));
  });
}
