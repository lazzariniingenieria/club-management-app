import 'package:club_management_app/features/payments/presentation/formatting/peso_amount.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reading an amount', () {
    test('whole pesos become cents', () {
      expect(PesoAmount.centsFrom('15.000'), 1500000);
    });

    test('one or two decimals are cents, as the API takes them', () {
      expect(PesoAmount.centsFrom('15.000,5'), 1500050);
      expect(PesoAmount.centsFrom('15.000,05'), 1500005);
    });

    test('an empty field has no amount', () {
      expect(PesoAmount.centsFrom(''), isNull);
    });
  });

  group('showing an amount', () {
    test('whole pesos go without decimals', () {
      expect(PesoAmount.textFor(1500000), '15.000');
    });

    test('cents always show two digits', () {
      expect(PesoAmount.textFor(1500050), '15.000,50');
      expect(PesoAmount.textFor(1500005), '15.000,05');
    });
  });

  group('typing an amount', () {
    const formatter = PesoAmountFormatter();

    TextEditingValue typed(String before, String insert) {
      final old = TextEditingValue(
        text: before,
        selection: TextSelection.collapsed(offset: before.length),
      );
      final text = before + insert;

      return formatter.formatEditUpdate(
        old,
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      );
    }

    TextEditingValue erased(String before) {
      final text = before.substring(0, before.length - 1);

      return formatter.formatEditUpdate(
        TextEditingValue(
          text: before,
          selection: TextSelection.collapsed(offset: before.length),
        ),
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      );
    }

    TextEditingValue replacedAll(String before, String replacement) {
      return formatter.formatEditUpdate(
        TextEditingValue(
          text: before,
          selection: TextSelection(baseOffset: 0, extentOffset: before.length),
        ),
        TextEditingValue(
          text: replacement,
          selection: TextSelection.collapsed(offset: replacement.length),
        ),
      );
    }

    test('groups thousands while typing', () {
      expect(typed('1.500', '0').text, '15.000');
    });

    test('a comma starts the decimals', () {
      final value = typed('15.000', ',');

      expect(value.text, '15.000,');
      expect(value.selection.baseOffset, value.text.length);
    });

    test('a dot typed by hand also starts the decimals', () {
      expect(typed('15.000', '.').text, '15.000,');
    });

    test('a decimal mark with nothing before it reads as zero', () {
      expect(typed('', ',').text, '0,');
    });

    test('takes no third decimal and no second decimal mark', () {
      expect(typed('15.000,50', '1').text, '15.000,50');
      expect(typed('15.000,5', ',').text, '15.000,5');
    });

    test('stops at eight whole digits, as the API does', () {
      expect(typed('12.345.678', '9').text, '12.345.678');
    });

    test('erasing the decimal mark drops the decimals', () {
      expect(erased('15.000,').text, '15.000');
    });

    test('erasing the decimal mark of an amount with cents keeps the pesos',
        () {
      final value = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '15.000,50',
          selection: TextSelection.collapsed(offset: 7),
        ),
        const TextEditingValue(
          text: '15.00050',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );

      expect(value.text, '15.000');
    });

    test('typing over the whole amount replaces it', () {
      expect(replacedAll('15.000,50', '2').text, '2');
    });

    test('erasing the whole amount empties the field', () {
      expect(replacedAll('15.000,50', '').text, '');
    });

    test('pasting over the whole amount takes the pasted one', () {
      expect(replacedAll('15.000,50', '3.500').text, '3.500');
    });

    test('erasing a thousands dot erases the digit before it', () {
      final value = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '15.000',
          selection: TextSelection.collapsed(offset: 3),
        ),
        const TextEditingValue(
          text: '15000',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );

      expect(value.text, '1.000');
      expect(value.selection.baseOffset, 1);
    });
  });
}
