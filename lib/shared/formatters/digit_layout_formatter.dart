import 'dart:math';

import 'package:flutter/services.dart';

typedef DigitLayout = String Function(String digits);

abstract final class DigitLayouts {
  static final RegExp _nonDigit = RegExp(r'\D');

  static String digitsOf(String text) => text.replaceAll(_nonDigit, '');

  static String groupedByThousands(String digits) {
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      if (index > 0 && remaining % 3 == 0) buffer.write('.');
      buffer.write(digits[index]);
    }

    return buffer.toString();
  }
}

class DigitLayoutFormatter extends TextInputFormatter {
  final DigitLayout layout;
  final int maxDigits;

  const DigitLayoutFormatter({required this.layout, required this.maxDigits});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final edit = _DigitEdit.between(oldValue, newValue).limitedTo(maxDigits);
    final text = layout(edit.digits);

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: _offsetAfterDigits(text, edit.digitsBeforeCursor),
      ),
    );
  }

  static int _offsetAfterDigits(String text, int digitCount) {
    if (digitCount == 0) return 0;
    var seen = 0;

    for (var index = 0; index < text.length; index++) {
      if (_isDigit(text[index]) && ++seen == digitCount) return index + 1;
    }

    return text.length;
  }
}

class _DigitEdit {
  final String digits;
  final int digitsBeforeCursor;

  const _DigitEdit(this.digits, this.digitsBeforeCursor);

  factory _DigitEdit.between(TextEditingValue before, TextEditingValue after) {
    final digits = DigitLayouts.digitsOf(after.text);
    final cursor = _digitsBefore(after.text, after.selection.end);
    final onlyRemovedASeparator = after.text.length < before.text.length &&
        digits == DigitLayouts.digitsOf(before.text);

    if (!onlyRemovedASeparator) return _DigitEdit(digits, cursor);

    final deletedForward = after.selection.end == before.selection.end;
    final target = deletedForward ? cursor : cursor - 1;
    final targetExists = target >= 0 && target < digits.length;
    if (!targetExists) return _DigitEdit(digits, cursor);

    return _DigitEdit(digits.replaceRange(target, target + 1, ''), target);
  }

  _DigitEdit limitedTo(int maxDigits) {
    if (digits.length <= maxDigits) return this;

    return _DigitEdit(
      digits.substring(0, maxDigits),
      min(digitsBeforeCursor, maxDigits),
    );
  }

  static int _digitsBefore(String text, int offset) {
    final end = offset < 0 ? text.length : min(offset, text.length);

    return DigitLayouts.digitsOf(text.substring(0, end)).length;
  }
}

bool _isDigit(String character) {
  final codeUnit = character.codeUnitAt(0);

  return codeUnit >= 0x30 && codeUnit <= 0x39;
}
