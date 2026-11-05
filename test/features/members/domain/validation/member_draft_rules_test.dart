import 'package:club_management_app/features/members/domain/validation/member_draft_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MemberFieldError? validate(MemberField field, String value) =>
      MemberDraftRules.validate(field, value);

  group('the fields the club cannot do without', () {
    test('a name made of spaces counts as empty', () {
      expect(
        validate(MemberField.firstName, '   '),
        MemberFieldError.required,
      );
      expect(validate(MemberField.lastName, ''), MemberFieldError.required);
      expect(validate(MemberField.dni, ' '), MemberFieldError.required);
    });

    test('a name within the column length is accepted', () {
      expect(validate(MemberField.firstName, 'Ana'), isNull);
      expect(
        validate(MemberField.lastName, 'A' * MemberDraftRules.maxNameLength),
        isNull,
      );
    });

    test('a name longer than the column is rejected before travelling', () {
      expect(
        validate(
          MemberField.lastName,
          'A' * (MemberDraftRules.maxNameLength + 1),
        ),
        MemberFieldError.tooLong,
      );
    });
  });

  group('dni', () {
    test('accepts the digits the admin reads off the document', () {
      expect(validate(MemberField.dni, '30111222'), isNull);
    });

    test('rejects the dots an admin types out of habit', () {
      expect(
        validate(MemberField.dni, '30.111.222'),
        MemberFieldError.nonNumericDni,
      );
    });

    test('rejects letters', () {
      expect(
        validate(MemberField.dni, '30111222A'),
        MemberFieldError.nonNumericDni,
      );
    });

    test('ignores surrounding spaces, as the submitted draft is trimmed', () {
      expect(validate(MemberField.dni, ' 30111222 '), isNull);
    });

    test('accepts the 6 digits of an old enrolment book', () {
      expect(validate(MemberField.dni, '123456'), isNull);
    });

    test('rejects fewer than 6 or more than 8 digits', () {
      expect(
        validate(MemberField.dni, '12345'),
        MemberFieldError.invalidDniLength,
      );
      expect(
        validate(MemberField.dni, '301112223'),
        MemberFieldError.invalidDniLength,
      );
    });
  });

  group('the optional fields', () {
    test('an empty phone or email is valid, because the club may not have it',
        () {
      expect(validate(MemberField.phone, ''), isNull);
      expect(validate(MemberField.email, '   '), isNull);
    });

    test('a well formed email passes', () {
      expect(validate(MemberField.email, 'ana@club.com.ar'), isNull);
    });

    test('an email without a domain or without an at sign is rejected', () {
      expect(
        validate(MemberField.email, 'ana@club'),
        MemberFieldError.malformedEmail,
      );
      expect(
        validate(MemberField.email, 'ana.club.com'),
        MemberFieldError.malformedEmail,
      );
    });

    test('a phone longer than the column is rejected', () {
      expect(
        validate(
          MemberField.phone,
          '1' * (MemberDraftRules.maxPhoneLength + 1),
        ),
        MemberFieldError.tooLong,
      );
    });
  });
}
