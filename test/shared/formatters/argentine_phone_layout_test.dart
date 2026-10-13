import 'package:club_management_app/shared/formatters/argentine_phone_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String format(String digits) => ArgentinePhoneLayout.format(digits);

  group('the hyphen goes right after the area code', () {
    test('a four-digit area code, like the club town', () {
      expect(format('3498462578'), '3498-462578');
      expect(format('2302123456'), '2302-123456');
    });

    test('a three-digit area code', () {
      expect(format('3424123456'), '342-4123456');
      expect(format('3415551234'), '341-5551234');
      expect(format('2304123456'), '230-4123456');
    });

    test('Buenos Aires', () {
      expect(format('1155667788'), '11-55667788');
    });

    test('a mobile written with its 15', () {
      expect(format('349815462578'), '3498-15462578');
    });

    test('the national prefix stays in front', () {
      expect(format('03424123456'), '0342-4123456');
    });
  });

  group('while the number is still being typed', () {
    test('no hyphen before the area code is complete', () {
      expect(format('349'), '349');
      expect(format('3498'), '3498');
      expect(format('34984'), '3498-4');
    });

    test('a three-digit code shows its hyphen once no longer code fits', () {
      expect(format('3424'), '342-4');
    });

    test('waits while a three and a four-digit code are both possible', () {
      expect(format('3435'), '3435');
      expect(format('34351'), '343-51');
      expect(format('34355'), '3435-5');
    });
  });

  test('a number without area code is left alone', () {
    expect(format('462578'), '462578');
    expect(format('15462578'), '15462578');
  });
}
