import 'package:equatable/equatable.dart';

enum MemberStatus { active, inactive }

class Member extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String dni;
  final MemberStatus status;
  final int daysOverdue;
  final String? phone;
  final String? email;

  const Member({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.status,
    required this.daysOverdue,
    this.phone,
    this.email,
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
      [id, firstName, lastName, dni, status, daysOverdue, phone, email];
}

const Map<String, String> _accentFolding = {
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'â': 'a',
  'ã': 'a',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'ê': 'e',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'î': 'i',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ô': 'o',
  'õ': 'o',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'û': 'u',
  'ñ': 'n',
  'ç': 'c',
};

String _withoutAccents(String value) {
  final buffer = StringBuffer();

  for (final character in value.split('')) {
    buffer.write(_accentFolding[character] ?? character);
  }

  return buffer.toString();
}
