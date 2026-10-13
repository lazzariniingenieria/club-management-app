import 'package:club_management_app/shared/formatters/digit_layout_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the layouts', () {
    test('a dni is grouped by thousands from the right', () {
      expect(DigitLayouts.groupedByThousands(''), '');
      expect(DigitLayouts.groupedByThousands('301'), '301');
      expect(DigitLayouts.groupedByThousands('3011'), '3.011');
      expect(DigitLayouts.groupedByThousands('5123456'), '5.123.456');
      expect(DigitLayouts.groupedByThousands('30111222'), '30.111.222');
    });

    test('only the digits survive', () {
      expect(DigitLayouts.digitsOf('DNI 30.111.222'), '30111222');
      expect(DigitLayouts.digitsOf('+54 11 5566-7788'), '541155667788');
    });
  });

  group('the formatter', () {
    const dniFormatter = DigitLayoutFormatter(
      layout: DigitLayouts.groupedByThousands,
      maxDigits: 8,
    );

    TextEditingValue valueAt(String text, int cursor) => TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: cursor),
        );

    TextEditingValue edit(String before, String after, {required int cursor}) =>
        dniFormatter.formatEditUpdate(
          valueAt(before, before.length),
          valueAt(after, cursor),
        );

    test('lays out the digits as they are typed, keeping the cursor last', () {
      final result = edit('30.111', '30.1112', cursor: 7);

      expect(result.text, '301.112');
      expect(result.selection.baseOffset, 7);
    });

    test('drops whatever is not a digit from a paste', () {
      expect(edit('', 'DNI 30.111.222', cursor: 14).text, '30.111.222');
    });

    test('keeps the cursor after the same digit when typing mid-number', () {
      final result = edit('30.111.22', '30.9111.22', cursor: 4);

      expect(result.text, '30.911.122');
      expect(result.selection.baseOffset, 4);
    });

    test('a backspace on a separator deletes the digit behind it', () {
      final result = dniFormatter.formatEditUpdate(
        valueAt('30.111', 3),
        valueAt('30111', 2),
      );

      expect(result.text, '3.111');
      expect(result.selection.baseOffset, 1);
    });

    test('a forward delete on a separator deletes the digit after it', () {
      final result = dniFormatter.formatEditUpdate(
        valueAt('30.111', 2),
        valueAt('30111', 2),
      );

      expect(result.text, '3.011');
      expect(result.selection.baseOffset, 3);
    });

    test('ignores digits beyond the limit', () {
      expect(edit('30.111.222', '301112229', cursor: 9).text, '30.111.222');
    });
  });
}
