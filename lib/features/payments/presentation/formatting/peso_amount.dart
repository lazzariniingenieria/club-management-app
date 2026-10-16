import 'dart:math';

import 'package:flutter/services.dart';

import '../../../../shared/formatters/digit_layout_formatter.dart';

abstract final class PesoAmount {
  static const int maxWholeDigits = 8;
  static const int maxDecimalDigits = 2;
  static const String decimalMark = ',';

  static int? centsFrom(String text) {
    final parts = text.split(decimalMark);
    final whole = DigitLayouts.digitsOf(parts.first);
    final decimals = parts.length > 1 ? DigitLayouts.digitsOf(parts[1]) : '';
    if (whole.isEmpty && decimals.isEmpty) return null;

    final paddedDecimals = decimals.padRight(maxDecimalDigits, '0');

    return int.parse(whole.isEmpty ? '0' : whole) * 100 +
        int.parse(paddedDecimals.substring(0, maxDecimalDigits));
  }

  static String textFor(int? cents) {
    if (cents == null) return '';

    final whole = DigitLayouts.groupedByThousands('${cents ~/ 100}');
    final remainder = cents % 100;
    if (remainder == 0) return whole;

    return '$whole$decimalMark${remainder.toString().padLeft(2, '0')}';
  }
}

class PesoAmountFormatter extends TextInputFormatter {
  const PesoAmountFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final amount = _ParsedAmount.of(_RawEdit.between(oldValue, newValue));
    if (amount == null) return oldValue;

    return TextEditingValue(
      text: amount.text,
      selection: TextSelection.collapsed(offset: amount.cursorOffset),
    );
  }
}

class _RawEdit {
  final String text;
  final int cursor;

  const _RawEdit(this.text, this.cursor);

  static _RawEdit between(TextEditingValue before, TextEditingValue after) {
    final cursor = min(max(after.selection.end, 0), after.text.length);
    if (_removedDecimalMark(before, after)) {
      final whole = before.text.split(PesoAmount.decimalMark).first;

      return _RawEdit(whole, whole.length);
    }
    if (_removedOnlyGrouping(before, after) && cursor > 0) {
      return _RawEdit(
          after.text.replaceRange(cursor - 1, cursor, ''), cursor - 1);
    }

    return _RawEdit(after.text, cursor);
  }

  static bool _removedDecimalMark(
    TextEditingValue before,
    TextEditingValue after,
  ) {
    if (after.text.length != before.text.length - 1) return false;
    final markAt = before.text.indexOf(PesoAmount.decimalMark);

    return markAt >= 0 &&
        before.text.replaceRange(markAt, markAt + 1, '') == after.text;
  }

  static bool _removedOnlyGrouping(
    TextEditingValue before,
    TextEditingValue after,
  ) {
    return after.text.length == before.text.length - 1 &&
        DigitLayouts.digitsOf(after.text) == DigitLayouts.digitsOf(before.text);
  }
}

class _ParsedAmount {
  final String whole;
  final String? decimals;
  final int digitsBeforeCursor;
  final bool cursorAfterMark;

  const _ParsedAmount({
    required this.whole,
    required this.decimals,
    required this.digitsBeforeCursor,
    required this.cursorAfterMark,
  });

  static _ParsedAmount? of(_RawEdit raw) {
    final parts = raw.text.split(PesoAmount.decimalMark);
    if (parts.length > 2) return null;

    final typedWhole = DigitLayouts.digitsOf(parts.first);
    final decimals = parts.length == 2 ? DigitLayouts.digitsOf(parts[1]) : null;
    final whole = _normalizedWhole(typedWhole, hasDecimals: decimals != null);
    if (whole.length > PesoAmount.maxWholeDigits) return null;
    if ((decimals?.length ?? 0) > PesoAmount.maxDecimalDigits) return null;

    final beforeCursor = raw.text.substring(0, raw.cursor);
    final typedDigitsBefore = DigitLayouts.digitsOf(beforeCursor).length;

    return _ParsedAmount(
      whole: whole,
      decimals: decimals,
      digitsBeforeCursor: max(
        0,
        typedDigitsBefore + whole.length - typedWhole.length,
      ),
      cursorAfterMark: beforeCursor.contains(PesoAmount.decimalMark),
    );
  }

  String get text {
    final grouped = DigitLayouts.groupedByThousands(whole);
    final fraction = decimals;

    return fraction == null
        ? grouped
        : '$grouped${PesoAmount.decimalMark}$fraction';
  }

  int get cursorOffset {
    final formatted = text;
    if (cursorAfterMark && digitsBeforeCursor == whole.length) {
      return formatted.indexOf(PesoAmount.decimalMark) + 1;
    }

    var seen = 0;
    for (var index = 0; index < formatted.length; index++) {
      if (seen == digitsBeforeCursor) return index;
      if (_isDigit(formatted[index])) seen++;
    }

    return formatted.length;
  }

  static String _normalizedWhole(String digits, {required bool hasDecimals}) {
    final trimmed = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    return trimmed.isEmpty && hasDecimals ? '0' : trimmed;
  }
}

bool _isDigit(String character) {
  final codeUnit = character.codeUnitAt(0);

  return codeUnit >= 0x30 && codeUnit <= 0x39;
}
