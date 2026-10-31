import '../../../../shared/validation/dni_rules.dart';

enum MemberField { firstName, lastName, dni, phone, email }

enum MemberFieldError {
  required,
  tooLong,
  nonNumericDni,
  invalidDniLength,
  malformedEmail,
}

abstract final class MemberDraftRules {
  static const int maxNameLength = 100;
  static const int maxDniLength = DniRules.maxLength;
  static const int maxPhoneLength = 30;
  static const int maxEmailLength = 150;

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static MemberFieldError? validate(MemberField field, String value) {
    final trimmed = value.trim();

    return switch (field) {
      MemberField.firstName => _validateName(trimmed),
      MemberField.lastName => _validateName(trimmed),
      MemberField.dni => _validateDni(trimmed),
      MemberField.phone => _validateLength(trimmed, maxPhoneLength),
      MemberField.email => _validateEmail(trimmed),
    };
  }

  static MemberFieldError? _validateName(String value) {
    if (value.isEmpty) return MemberFieldError.required;

    return _validateLength(value, maxNameLength);
  }

  static MemberFieldError? _validateDni(String value) {
    return switch (DniRules.validate(value)) {
      DniError.required => MemberFieldError.required,
      DniError.nonNumeric => MemberFieldError.nonNumericDni,
      DniError.invalidLength => MemberFieldError.invalidDniLength,
      null => null,
    };
  }

  static MemberFieldError? _validateEmail(String value) {
    if (value.isEmpty) return null;
    if (!_email.hasMatch(value)) return MemberFieldError.malformedEmail;

    return _validateLength(value, maxEmailLength);
  }

  static MemberFieldError? _validateLength(String value, int maxLength) {
    if (value.length > maxLength) return MemberFieldError.tooLong;

    return null;
  }
}
