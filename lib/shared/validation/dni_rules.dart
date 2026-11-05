enum DniError { required, nonNumeric, invalidLength }

abstract final class DniRules {
  static const int minLength = 6;
  static const int maxLength = 8;

  static final RegExp _onlyDigits = RegExp(r'^\d+$');

  static DniError? validate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return DniError.required;
    if (!_onlyDigits.hasMatch(trimmed)) return DniError.nonNumeric;
    if (trimmed.length < minLength || trimmed.length > maxLength) {
      return DniError.invalidLength;
    }

    return null;
  }
}
