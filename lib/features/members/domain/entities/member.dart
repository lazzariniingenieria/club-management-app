import 'package:equatable/equatable.dart';

enum MemberStatus { active, inactive }

class Member extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String dni;
  final MemberStatus status;
  final int daysOverdue;

  const Member({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.status,
    required this.daysOverdue,
  });

  String get fullName => '$firstName $lastName';

  bool get isActive => status == MemberStatus.active;

  bool get isOverdue => daysOverdue > 0;

  String get sortKey => _withoutAccents('$lastName $firstName'.toLowerCase());

  bool matches(String query) {
    final normalizedQuery = _withoutAccents(query.trim().toLowerCase());
    if (normalizedQuery.isEmpty) return true;

    final haystack = '${_withoutAccents(fullName.toLowerCase())} $dni';

    return haystack.contains(normalizedQuery);
  }

  @override
  List<Object?> get props =>
      [id, firstName, lastName, dni, status, daysOverdue];
}

const String _accentedCharacters = 'áàäâãéèëêíìïîóòöôõúùüûñç';
const String _plainCharacters = 'aaaaaeeeeiiiiooooouuuunc';

String _withoutAccents(String value) {
  final buffer = StringBuffer();

  for (final character in value.split('')) {
    final accentIndex = _accentedCharacters.indexOf(character);
    buffer.write(accentIndex < 0 ? character : _plainCharacters[accentIndex]);
  }

  return buffer.toString();
}
