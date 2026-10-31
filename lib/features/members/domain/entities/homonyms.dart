import 'member.dart';

class Homonyms {
  final Set<String> _repeatedNames;

  Homonyms.among(Iterable<Member> members)
      : _repeatedNames = _repeatedNamesOf(members);

  bool includes(Member member) => _repeatedNames.contains(member.sortKey);

  static Set<String> _repeatedNamesOf(Iterable<Member> members) {
    final seen = <String>{};

    return {
      for (final member in members)
        if (!seen.add(member.sortKey)) member.sortKey,
    };
  }
}
