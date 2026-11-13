import 'package:club_management_app/features/courts/domain/validation/court_draft_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the name is required, blank spaces included', () {
    expect(
      CourtDraftRules.validate(CourtField.name, '   '),
      CourtFieldError.required,
    );
  });

  test('the name fits the 100 characters the API accepts', () {
    expect(CourtDraftRules.validate(CourtField.name, 'a' * 100), isNull);
    expect(
      CourtDraftRules.validate(CourtField.name, 'a' * 101),
      CourtFieldError.tooLong,
    );
  });

  test('the sport is optional and fits 50 characters', () {
    expect(CourtDraftRules.validate(CourtField.type, ''), isNull);
    expect(
      CourtDraftRules.validate(CourtField.type, 'a' * 51),
      CourtFieldError.tooLong,
    );
  });
}
