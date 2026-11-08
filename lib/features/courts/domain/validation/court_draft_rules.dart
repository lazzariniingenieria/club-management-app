enum CourtField { name, type }

enum CourtFieldError { required, tooLong }

abstract final class CourtDraftRules {
  static const int maxNameLength = 100;
  static const int maxTypeLength = 50;

  static CourtFieldError? validate(CourtField field, String value) {
    final trimmed = value.trim();

    return switch (field) {
      CourtField.name => _validateName(trimmed),
      CourtField.type => _validateLength(trimmed, maxTypeLength),
    };
  }

  static CourtFieldError? _validateName(String value) {
    if (value.isEmpty) return CourtFieldError.required;

    return _validateLength(value, maxNameLength);
  }

  static CourtFieldError? _validateLength(String value, int maxLength) {
    if (value.length > maxLength) return CourtFieldError.tooLong;

    return null;
  }
}
