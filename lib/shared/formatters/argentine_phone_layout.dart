import 'dart:math';

abstract final class ArgentinePhoneLayout {
  // Four-digit area code prefixes, taken from the AR fixed-line formats in
  // libphonenumber's PhoneNumberMetadata.xml (google/libphonenumber@33be566).
  static final RegExp _fourDigitAreaCode = RegExp(
    r'2(?:[23]02|6(?:[25]|4(?:64|[78]))|9(?:[02356]|4(?:[0268]|5[2-6])|72|8[23]))'
    r'|3(?:3[28]|4(?:[04679]|3(?:5(?:4[0-25689]|[56])|[78])|58|8[2379])'
    r'|5(?:[2467]|3[237]|8(?:[23]|4(?:[45]|60)|5(?:4[0-39]|5|64)))'
    r'|7[1-578]|8(?:[2469]|3[278]|54(?:4|5[13-7]|6[89])|86[3-6]))'
    r'|2(?:2[24-9]|3[1-59]|47)|38(?:[58][78]|7[378])|3(?:454|85[56])[46]'
    r'|3(?:4(?:36|5[56])|8(?:[38]5|76))[4-6]',
  );
  static final RegExp _geographicStart = RegExp('[23]');
  static const String _nationalPrefix = '0';
  static const String _buenosAiresAreaCode = '11';
  static const int _digitsThatSettleTheAreaCode = 6;

  static String format(String digits) {
    if (digits.startsWith(_nationalPrefix)) {
      return '$_nationalPrefix${format(digits.substring(1))}';
    }
    final areaCodeLength = _areaCodeLengthOf(digits);
    if (areaCodeLength == null || digits.length <= areaCodeLength) {
      return digits;
    }

    return '${digits.substring(0, areaCodeLength)}-'
        '${digits.substring(areaCodeLength)}';
  }

  static int? _areaCodeLengthOf(String digits) {
    if (digits.startsWith(_buenosAiresAreaCode)) return 2;
    if (digits.length < 4 || !digits.startsWith(_geographicStart)) return null;
    if (_fourDigitAreaCode.matchAsPrefix(digits) != null) return 4;

    return _mayStillHaveFourDigitAreaCode(digits) ? null : 3;
  }

  static bool _mayStillHaveFourDigitAreaCode(String digits) {
    final missing = _digitsThatSettleTheAreaCode - digits.length;
    if (missing <= 0) return false;

    for (var tail = 0; tail < pow(10, missing); tail++) {
      final candidate = digits + '$tail'.padLeft(missing, '0');
      if (_fourDigitAreaCode.matchAsPrefix(candidate) != null) return true;
    }

    return false;
  }
}
